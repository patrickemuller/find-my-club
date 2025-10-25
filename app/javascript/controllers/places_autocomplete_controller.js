import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="places-autocomplete"
export default class extends Controller {
  static targets = ["input", "hiddenField", "nameField", "results"]

  connect() {
    this.selectedIndex = -1
    this.debounceTimeout = null
    this.setupEventListeners()
    this.createResultsContainer()
  }

  disconnect() {
    this.removeResultsContainer()
  }

  setupEventListeners() {
    // Listen for input changes with debouncing
    this.inputTarget.addEventListener('input', (e) => {
      clearTimeout(this.debounceTimeout)
      this.debounceTimeout = setTimeout(() => {
        this.fetchPredictions(e.target.value)
      }, 300) // 300ms debounce
    })

    // Listen for keyboard navigation
    this.inputTarget.addEventListener('keydown', (e) => {
      this.handleKeydown(e)
    })

    // Close results when clicking outside
    document.addEventListener('click', (e) => {
      if (!this.element.contains(e.target)) {
        this.hideResults()
      }
    })
  }

  createResultsContainer() {
    if (!this.hasResultsTarget) {
      const resultsDiv = document.createElement('div')
      resultsDiv.dataset.placesAutocompleteTarget = 'results'
      resultsDiv.className = 'absolute z-10 w-full mt-1 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md shadow-lg max-h-60 overflow-auto hidden'
      this.inputTarget.parentElement.style.position = 'relative'
      this.inputTarget.parentElement.appendChild(resultsDiv)
    }
  }

  removeResultsContainer() {
    if (this.hasResultsTarget) {
      this.resultsTarget.remove()
    }
  }

  async fetchPredictions(query) {
    if (!query || query.trim().length < 2) {
      this.hideResults()
      return
    }

    try {
      const response = await fetch(`/places/autocomplete?query=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.displayPredictions(data.predictions || [])
    } catch (error) {
      console.error('Error fetching place predictions:', error)
      this.hideResults()
    }
  }

  displayPredictions(predictions) {
    if (!this.hasResultsTarget) return

    if (predictions.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = ''
    this.selectedIndex = -1

    predictions.forEach((prediction, index) => {
      const item = document.createElement('div')
      item.className = 'px-4 py-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 text-sm text-gray-900 dark:text-gray-100'
      item.dataset.index = index
      item.dataset.placeId = prediction.place_id
      item.dataset.description = prediction.description
      item.textContent = prediction.description

      item.addEventListener('click', () => {
        this.selectPrediction(prediction)
      })

      this.resultsTarget.appendChild(item)
    })

    this.showResults()
  }

  selectPrediction(prediction) {
    const locationName = prediction.description

    // Create embeddable Google Maps URL in the format: https://maps.google.com/?q=Location+Name
    const mapsUrl = `https://maps.google.com/?q=${encodeURIComponent(locationName)}`

    // Update the hidden field with the Google Maps embeddable URL
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = mapsUrl
    }

    // Update the location_name hidden field with the description
    if (this.hasNameFieldTarget) {
      this.nameFieldTarget.value = locationName
    }

    // Update the input to show the location name
    this.inputTarget.value = locationName

    this.hideResults()
  }

  handleKeydown(e) {
    if (!this.hasResultsTarget || this.resultsTarget.classList.contains('hidden')) {
      return
    }

    const items = this.resultsTarget.querySelectorAll('[data-index]')

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightItem(items)
        break
      case 'ArrowUp':
        e.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.highlightItem(items)
        break
      case 'Enter':
        e.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          const item = items[this.selectedIndex]
          const prediction = {
            place_id: item.dataset.placeId,
            description: item.dataset.description
          }
          this.selectPrediction(prediction)
        }
        break
      case 'Escape':
        this.hideResults()
        break
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-gray-100', 'dark:bg-gray-700')
      } else {
        item.classList.remove('bg-gray-100', 'dark:bg-gray-700')
      }
    })

    // Scroll to highlighted item
    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].scrollIntoView({ block: 'nearest' })
    }
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('hidden')
    }
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('hidden')
      this.selectedIndex = -1
    }
  }
}
