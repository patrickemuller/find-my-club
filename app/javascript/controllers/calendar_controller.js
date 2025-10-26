import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthDisplay", "grid"]
  static values = {
    events: Array
  }

  connect() {
    const now = new Date()
    this.currentMonth = now.getMonth()
    this.currentYear = now.getFullYear()
    this.renderCalendar()
  }

  previousMonth() {
    this.currentMonth--
    if (this.currentMonth < 0) {
      this.currentMonth = 11
      this.currentYear--
    }
    this.renderCalendar()
  }

  nextMonth() {
    this.currentMonth++
    if (this.currentMonth > 11) {
      this.currentMonth = 0
      this.currentYear++
    }
    this.renderCalendar()
  }

  goToToday() {
    const now = new Date()
    this.currentMonth = now.getMonth()
    this.currentYear = now.getFullYear()
    this.renderCalendar()
  }

  renderCalendar() {
    // Update month display
    const monthNames = ["January", "February", "March", "April", "May", "June",
                        "July", "August", "September", "October", "November", "December"]
    this.monthDisplayTarget.textContent = `${monthNames[this.currentMonth]} ${this.currentYear}`
    this.monthDisplayTarget.setAttribute("datetime", `${this.currentYear}-${String(this.currentMonth + 1).padStart(2, '0')}`)

    // Generate calendar grid
    const firstDay = this.getFirstDayOfMonth(this.currentYear, this.currentMonth)
    const daysInMonth = this.getDaysInMonth(this.currentYear, this.currentMonth)
    const daysInPrevMonth = this.getDaysInMonth(this.currentYear, this.currentMonth - 1)

    let html = ''
    let dayCounter = 1
    let nextMonthCounter = 1

    // Generate 42 cells (6 rows x 7 days)
    for (let i = 0; i < 42; i++) {
      let dayNum, month, year, isCurrentMonth = false

      if (i < firstDay) {
        // Previous month days
        dayNum = daysInPrevMonth - firstDay + i + 1
        month = this.currentMonth - 1
        year = this.currentYear
        if (month < 0) {
          month = 11
          year--
        }
      } else if (dayCounter <= daysInMonth) {
        // Current month days
        dayNum = dayCounter++
        month = this.currentMonth
        year = this.currentYear
        isCurrentMonth = true
      } else {
        // Next month days
        dayNum = nextMonthCounter++
        month = this.currentMonth + 1
        year = this.currentYear
        if (month > 11) {
          month = 0
          year++
        }
      }

      const date = new Date(year, month, dayNum)
      const dateStr = this.formatDateISO(date)
      const eventsForDay = this.getEventsForDate(dateStr)
      const isTodayFlag = this.isToday(date)

      html += this.renderDayCell(dayNum, date, eventsForDay, isCurrentMonth, isTodayFlag)
    }

    this.gridTarget.innerHTML = html
  }

  renderDayCell(dayNum, date, events, isCurrentMonth, isToday) {
    const dateStr = this.formatDateISO(date)
    const currentMonthAttr = isCurrentMonth ? 'data-is-current-month' : ''
    const todayAttr = isToday ? 'data-is-today' : ''

    let eventsHtml = ''
    if (events.length > 0) {
      eventsHtml = '<ol class="mt-2">'
      // Show up to 2 events per day
      const displayEvents = events.slice(0, 2)
      displayEvents.forEach(event => {
        const time = this.formatTime(event.starts_at)
        eventsHtml += `
          <li>
            <a href="${event.url}" target="_blank" class="group inset-1 flex rounded-lg bg-orange-50 p-2 text-xs/5 hover:bg-orange-100 dark:bg-orange-600/15 dark:hover:bg-orange-600/20">
              <p class="flex-auto truncate font-medium text-gray-900 group-hover:text-orange-600 dark:text-white dark:group-hover:text-orange-400">
                ${this.escapeHtml(event.name)}
              </p>
              <time datetime="${event.starts_at}"
                    class="ml-3 hidden flex-none text-gray-500 group-hover:text-orange-600 xl:block dark:text-gray-400 dark:group-hover:text-orange-400">
                ${time}
              </time>
            </a>
          </li>
        `
      })
      // Show "+N more" if there are more than 2 events
      if (events.length > 2) {
        eventsHtml += `
          <li>
            <p class="text-xs text-gray-500 dark:text-gray-400">+${events.length - 2} more</p>
          </li>
        `
      }
      eventsHtml += '</ol>'
    }

    return `
      <div ${currentMonthAttr} ${todayAttr}
           class="min-h-32 group relative bg-gray-50 px-3 py-2 text-gray-500 data-is-current-month:bg-white dark:bg-gray-900 dark:text-gray-400 dark:not-data-is-current-month:before:pointer-events-none dark:not-data-is-current-month:before:absolute dark:not-data-is-current-month:before:inset-0 dark:not-data-is-current-month:before:bg-gray-800/50 dark:data-is-current-month:bg-gray-900">
        <time datetime="${dateStr}"
              class="relative group-not-data-is-current-month:opacity-75 in-data-is-today:flex in-data-is-today:size-6 in-data-is-today:items-center in-data-is-today:justify-center in-data-is-today:rounded-full in-data-is-today:bg-orange-600 in-data-is-today:font-semibold in-data-is-today:text-white dark:in-data-is-today:bg-orange-500">
          ${dayNum}
        </time>
        ${eventsHtml}
      </div>
    `
  }

  getFirstDayOfMonth(year, month) {
    const date = new Date(year, month, 1)
    const day = date.getDay()
    // Convert Sunday (0) to 6, and shift so Monday is 0
    return day === 0 ? 6 : day - 1
  }

  getDaysInMonth(year, month) {
    // Handle month wrapping
    if (month < 0) {
      month = 11
      year--
    } else if (month > 11) {
      month = 0
      year++
    }
    return new Date(year, month + 1, 0).getDate()
  }

  getEventsForDate(dateStr) {
    return this.eventsValue.filter(event => {
      const eventDate = new Date(event.starts_at)
      const eventDateStr = this.formatDateISO(eventDate)
      return eventDateStr === dateStr
    })
  }

  formatDateISO(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  formatTime(datetimeStr) {
    const date = new Date(datetimeStr)
    let hours = date.getHours()
    const ampm = hours >= 12 ? 'PM' : 'AM'
    hours = hours % 12
    hours = hours ? hours : 12 // 0 should be 12
    return `${hours}${ampm}`
  }

  isToday(date) {
    const today = new Date()
    return date.getDate() === today.getDate() &&
           date.getMonth() === today.getMonth() &&
           date.getFullYear() === today.getFullYear()
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
