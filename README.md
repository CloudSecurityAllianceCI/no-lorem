Never leave placeholder text like _Lorem ipsum dolor sit amet..._ slip into production. 

**No-lorem** is a tool that can search through ruby code for undesired words in strings or constants 
identifying undesired libraries. **No-lorem** can also search `.erb` or `.slim` files for undesired words or
expressions. 

When searching through ruby files, **No-lorem** looks both for undesired words in strings and constants.
When searching through `.erb` or `.slim` files, **No-lorem** only looks for undesired words (ignoring 
constants).

## Installation

**No-lorem** can be installed using `bundler`, by adding a line for it in your `Gemfile`.

```ruby
gem 'no-lorem', require: false, git: "https://github.com/CloudSecurityAllianceCI/no-lorem.git"
```

## Basic use

```
Usage: no-lorem [options] <path>
    -c, --config FILE                Load configuration file
    -x, --exclude PATH               Exclude PATH from scan
    -a, --all                        Signal all errors on the same source line
    -f, --first                      Signal first error on the same source line (default)
        --[no-]color                 Run with colored output in terminal
    -v, --verbose                    Display additional debugging information
    -W, --deny-word WORD             Add word to denylist
    -K, --deny-constant CONSTANT     Add constant to denylist
    -w, --warn-word WORD             Add word to warning list
    -k, --warn-constant CONSTANT     Add constant to warning list
```

To search for the words _lorem_ and _ipsum_ in the `app` directory and all its subdirectories:

```sh
$ bundle exec no-lorem -W "lorem" -W "ipsum" app/
```

If any of words _lorem_ or _ipsum_ are found, an error message is printed and the program exits with status code 1.

To search for the module "Faker" in any ruby file in the `app` directory and all its subdirectories. 

```sh
$ bundle exec no-lorem -K Faker app/
```

If the ruby constant "Faker" is found, an error message is printed and the program exits with status code 1.

It's also possible to use egular expressions, for example to search for URLs containing 'example.com'.

```sh
$ bundle exec no-lorem -W '/https?:\/\/example.com/' app/
```

Again, any match will cause the program to print an error message and exit with status code 1.

## Using a denylist

Instead of providing words or constants as command line arguments, it is possible to create a YAML configuration 
file, which can be used to specify a denylist for **No-lorem**.

The 3 examples described above can be summarized in the following configuration file:

```yaml
deny:
  words:
    - lorem 
    - ipsum 
    - /https?:\/\/example.com/
  constants:
    - Faker
```

Assuming this configuration file is named `denylist.yaml`, we can search our `app/` directory
with the following command:

```sh
$ bin/no-lorem -c denylist.yaml app/
```

If no configuration file is provided with the `-c` or `--config` option, **No-lorem** will try to load
the file `./.no-lorem.yaml` in the current directory and if that fails it will look for a file `~/.no-lorem.yaml`
in the user's home directory.
Finaly, if no configuration file is provided and no `-W`, `-w`, `-K` or `-k` options are specified, 
**no-lorem** stops and displays an error message.

## Using a warning list

In addition to specifying words or constants in a denylist, it's possible to create a **warning list**. 
A **warning list** will behave exactly like a deny list, except that matches cause the program with a status code
0 instead of 1. A warning is printed for all matches found. 

As an example, a warning list that searches for the expressions "TODO:" and "FIXME:" can be described in the following 
configuration file::

```yaml
warn:
  words:
    - 'TODO:'
    - 'FIXME:'
```

## Excluding files from the search

We can use the `--exclude` command line option to exclude a specific file or path from a search. 
For example to search through the `app/` directory but exclude everything in the `app/vendor` subdirectory
we can run the following command:

```sh
$ bundle exec no-lorem -w "lorem" -w "ipsum" --exclude app/vendor app/
```

Excluded files or directories can also be specified in the YAML configuration file:

```yaml                                                                                                                 
deny:                                                                                                                   
  words:                                                                                                                
    - lorem                                                                                                             
    - ipsum                                                                                                             
exclude:
  - app/vendor
``` 

## Status code

The **no-lorem** tool exists with the following status codes:

|Status code| Meaning
|-----------|---------------------
| 0         | No matches were found in the denylist (matches may still exist in the warning list).
| 1         | Matches were found in the denylist.
| 2         | There was a processing error (example: could not open a file).



