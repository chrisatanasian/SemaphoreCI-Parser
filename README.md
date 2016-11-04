# Semaphore Parser

## Setup
1. Clone this repo
2. Run `bundle install`

## How to Use
1. Run the script: `bundle exec ruby semaphore_parser.rb <semaphoreCI_auth_token> <project_hash_id> <branch_id> <build_number> (<folder>)`

### Todo:
1. Improve terminal interface


#### How to Use (Old style)
1. Open the build in Semaphore
2. Open the Javascript console (CMD + ALT + J in OS X)
3. Refresh the page
4. Enter this into the console to open all threads: ```var threads = $(".c-results_thread-box"); for (var i = 0; i < threads.length; i++) { threads[i].click(); }```
5. Once all the threads are opened and fully loaded, save the page with CMD + S
6. Run the script: `bundle exec ruby semaphore_parser_old.rb build.html <folder>` (where `build.html` is the semaphore build you saved, and `<folder>` (optional) is where you want the output saved)
