# Semaphore Parser

## Setup
1. Clone this repo
2. Run `bundle install`

## How to Use
1. Open the build in Semaphore
2. Open the Javascript console (cmd + alt + j in OS X)
3. Refresh the page
4. Enter this into the console to open all threads: ```var threads = $(".c-results_thread-box"); for (var i = 0; i < threads.length; i++) { threads[i].click(); }```
5. Once all the threads are opened and fully loaded, download the page with cmd + s
6. Run the script: `bundle exec ruby semaphore_parser.rb semaphore.html` (where `semaphore.html` is the build page you downloaded)
