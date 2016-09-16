# Semaphore Parser

## Instructions
1. Git clone this repo
2. Run `bundle install`
3. Open the build in Semaphore
4. Open the Javascript console (cmd + alt + j in OS X)
5. Refresh the page
6. Enter this into the console to open all threads: ```var threads = $(".c-results_thread-box");
for (var i = 0; i < threads.length; i++) { threads[i].click(); }```
7. Once all the threads are opened and fully loaded, download the page with cmd + s
8. Run the script: `bundle exec ruby semaphore_parser.rb semaphore.html` (where `semaphore.html` is the build page you downloaded)
