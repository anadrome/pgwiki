Minimalist Pandoc+Git wiki system

The general design is:

* Wiki pages are written in [Pandoc Markdown](https://pandoc.org/MANUAL.html#pandocs-markdown)
* All editing is done via git
* You set up a post-commit git webhook to ping the server on edits
* The server will then pull the repo, convert the Markdown files to static HTML, and
  serve up the HTML

If you use a git host that allows web-based editing of Markdown files (like
GitHub), this provides pretty close to a wiki experience: users can just edit
the .md files on the web, and the corresponding HTML is updated within a few
seconds of saving.

## Setup instructions

TODO
