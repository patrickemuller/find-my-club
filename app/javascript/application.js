// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Disable file attachments in Trix editor
document.addEventListener("trix-file-accept", function(event) {
  event.preventDefault()
  alert("File uploads are not supported at this time")
})
