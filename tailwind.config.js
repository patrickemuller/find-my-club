module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  // Classes that should ALWAYS be included in the precompiled assets
  // Useful for dynamic classes that are loaded through Turbo or other JS Fetch actions
  safelist: [],
}