# AI Article Review - Design

## Summary

An on-demand LLM review feature for articles. From the edit page, the user clicks "Review" to send the article body to a self-hosted Ollama instance via Langchain.rb. Review annotations appear as highlighted spans with margin comments on the rendered preview pane. Each suggestion can be accepted (applying the change to the markdown) or dismissed.

## Architecture

```
User clicks "Review"
  -> POST /articles/:slug/review (ArticleReviewsController#create)
  -> Enqueues ArticleReviewJob (Solid Queue)
  -> Job calls Ollama via Langchain::LLM::Ollama
  -> Ollama returns structured JSON annotations
  -> Job broadcasts via Action Cable (Solid Cable) to article-specific channel
  -> Stimulus controller receives annotations
  -> Renders highlights + margin comments on preview pane
  -> Accept: find-and-replace original text in textarea
  -> Dismiss: remove annotation
```

## LLM Integration via Langchain.rb

- **Gem:** `langchainrb` with built-in Ollama support
- **Configuration:** Environment variables
  - `OLLAMA_URL` (default: `http://localhost:11434`)
  - `OLLAMA_MODEL` (default: `qwen2.5:14b`)
- **Service:** `ArticleReviewService` wraps Langchain:

```ruby
class ArticleReviewService
  def initialize
    @llm = Langchain::LLM::Ollama.new(
      url: ENV.fetch("OLLAMA_URL", "http://localhost:11434"),
      default_options: { chat_model: ENV.fetch("OLLAMA_MODEL", "qwen2.5:14b") }
    )
  end

  def review(article_body)
    response = @llm.chat(messages: [
      { role: "system", content: system_prompt },
      { role: "user", content: article_body }
    ])
    JSON.parse(response.chat_completion)
  end
end
```

- **Prompt:** System prompt instructs the LLM to return a JSON array of annotations covering writing quality (grammar, clarity, tone) and content quality (logical consistency, missing points, argument strength), with concrete rewrite suggestions.
- **Provider flexibility:** Swapping to a different provider (OpenAI, Anthropic, Google) requires only changing the LLM class -- same `chat` interface.

## Annotation Data Shape

```json
[
  {
    "original_text": "The impact was very significant and really important",
    "suggestion": "The impact was significant",
    "category": "clarity",
    "explanation": "Remove redundant intensifiers for tighter prose"
  }
]
```

Categories: `grammar`, `clarity`, `content`, `structure`.

The LLM returns `original_text` as a verbatim excerpt from the article. This is used to both highlight the text in the preview pane and locate it in the markdown for accept-and-replace.

## UI Components

1. **Review button** -- Added next to the editor labels area, triggers `POST /articles/:slug/review`
2. **Loading indicator** -- Replaces the button with a spinner/pulsing state while the background job runs
3. **Highlighted spans** -- `original_text` matches in the preview pane get wrapped in colored `<mark>` elements (color coded per category)
4. **Margin comments** -- Each highlight has a positioned comment bubble showing: category badge, explanation, suggested text, and Accept/Dismiss buttons
5. **Accept action** -- Finds `original_text` in the textarea value, replaces with `suggestion`, re-renders the markdown preview, removes the annotation
6. **Dismiss action** -- Removes the annotation and its highlight

## Stimulus Controller

A new `article-review` controller on the markdown editor component:
- `review` action: sends POST to create review, shows loading state
- Subscribes to Action Cable channel `ArticleReviewChannel` scoped to the article
- `received` callback: parses annotations, calls `annotatePreview()` to insert highlights and margin comments
- `accept` action on each comment: replaces text in textarea, triggers preview re-render
- `dismiss` action on each comment: removes annotation

## Backend Components

| Component | Responsibility |
|-----------|---------------|
| `ArticleReviewsController` | Accepts review request, enqueues job, returns loading state |
| `ArticleReviewJob` | Calls `ArticleReviewService`, broadcasts results via Action Cable |
| `ArticleReviewService` | Wraps Langchain.rb Ollama client, constructs prompt, parses JSON response |
| `ArticleReviewChannel` | Action Cable channel, scoped to article ID |

## Routes

```ruby
resources :articles, param: :slug do
  resource :review, only: [:create], controller: "article_reviews"
end
```

`POST /articles/:slug/review` -- triggers the review.

## Configuration

```env
OLLAMA_URL=http://localhost:11434    # Ollama server URL
OLLAMA_MODEL=qwen2.5:14b            # Model to use for reviews
```

## Ephemeral Results

Review results are not persisted in the database. They exist only in the current browser session. The user can request a new review at any time.

## Error Handling

- **Ollama unreachable:** Broadcast error message via Action Cable, Stimulus shows "Review service unavailable" alert
- **JSON parsing failure:** Broadcast error, show "Could not parse review results"
- **No annotations returned:** Broadcast empty result, show "No suggestions found -- your article looks good!"

## Testing

- **Service test:** `ArticleReviewServiceTest` with stubbed Langchain responses, verifies prompt construction and JSON parsing
- **Job test:** `ArticleReviewJobTest` verifies it calls the service and broadcasts results via Action Cable
- **Controller test:** `ArticleReviewsControllerTest` -- auth required, enqueues job, returns appropriate response
- **System test:** Stubbed Ollama response, verify annotations appear on preview pane, test accept/dismiss actions
