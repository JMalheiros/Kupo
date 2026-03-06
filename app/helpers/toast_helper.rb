module ToastHelper
  def toast_classes(variant)
    base = "rounded-lg border px-4 py-3 shadow-lg backdrop-blur"
    case variant
    when :success
      "#{base} border-green-300 bg-green-50 text-green-800 dark:border-green-700 dark:bg-green-900/80 dark:text-green-200"
    when :destructive
      "#{base} border-red-300 bg-red-50 text-red-800 dark:border-red-700 dark:bg-red-900/80 dark:text-red-200"
    else
      "#{base} border-border bg-card text-card-foreground"
    end
  end
end
