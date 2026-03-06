# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "mustache" # @4.2.0
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.7.5
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.7.4
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.10
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.10
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.1.200
