# NVim custom config

## Installed packages

### lazy.nvim
Great and easy to use and configure package manager
Entrypoint for config
* ``.config/nvim/init.lua`` on Linux
* ``C:/Users/[user]/AppData/Local/nvim``

### Undotree
Allows you to see file edits as an n-ary tree that you can traverse to undo and redo changes.

### Harpoon
Lets you quickly switched between buffers

### Telescope
Uses ``fzf`` to find files within the opened file's folder

### LSP-Zero
Does everything an LSP does.

### Markdown preview
Lets you open a browser window with a preview of the Markdown file you're currently editing

### Fugitive
Git interface for NVim

### ...and more
WIP


## Installation
### Windows
Needs a [C/C++ compiler](https://www.freecodecamp.org/news/how-to-install-c-and-cpp-compiler-on-windows/) for Treesitter to work.
After that just clone the repository and add the ``nvim`` folder in ``C:/Users/[user]/AppData/Local/nvim``
Keep in mind that Treesitter will show an error for every new file opened for which it hasn't downloaded a parser. Just be patient and Treesitter will find and download one.

### Linux
Clone the repo into ``~/.config/``

## New mappings

**Leader has been set to `<Space>`**

### Navigation
* `<leader>pv` (project view) to open the file explorer
* `<leader>pf` (project find) to open Telescope's file finder
* `<leader>ps` (project search) to search for a specific word inside the project
* `<leader>map` (remap) to view the remappings file
* `<leader>rdm` (readme) to view this file
* `<leader>gcf` (go to config folder) to navigate to the settings folder

* `<C-p>` to navigate through Git files in current repo
* `<leader>gs` (git status) to do just that

* `<leader>a` (add) to add a new buffer to the Harpoon tracker
* `<C-e>` (edit) to view and edit the currently Harpoon-tracked buffers
* `<C-h>` to navigate to the Harpoon-tracked buffer 1
* `<C-n>` to navigate to the Harpoon-tracked buffer 2
* `<C-p>` to navigate to the Harpoon-tracked buffer 3
* `<C-l>` to navigate to the Harpoon-tracked buffer 4

### Text edition
* `<leader>u` (undo) to toggle Undotree
* `<leader>s` (substitute) to replace the word under the cursor globally
* `<leader>vrn` (rename) rename 

* `K` to move a selected block up
* `J` to move a selected block down

* `<leader>p` to keep pasted content in register after replacing
* `<leader>y` to yank to system clipboard

### LSP
* `<C-k>` (previous) previous item autosuggest
* `<C-j>` (next) next item in autosuggest
* `<C-y>` (yis) to confirm the choice
* `<C-Space>` to autocomplete the choice

* `<leader>vrr` (references) to find references in a project
* `<C-h>` (help) signature help

### Markdown
* `<leader>mdp` (markdown preview) to open Markdown Preview
* `<leader>mdps` (markdown preview stop) to close Markdown Preview


## TODO
* ~~Find debugger~~
* Set up debugger
* Get a file explorer
* ~~Configure fugitive~~
* Add package links to README
* Find a way to integrate with tmux
