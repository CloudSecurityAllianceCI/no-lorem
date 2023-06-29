Never leave placeholder text like _Lorem ipsum dolor sit amet..._ slip into production. 

**No-lorem** is a tool that can search through ruby code for undesired words in strings or constants 
identifying undesired libraries. **No-lorem** can also search `.erb` or `.slim` files for undesired words or
expressions. 

When searching through ruby files, **No-lorem** looks both for undesired words in strings and constants.
When searching through `.erb` or `.slim` files, **No-lorem** only looks for undesired words (ignoring 
constants).

## Installation

Install **No-lorem** as follows

```sh
$ gem install no-lorem
```

**No-lorem** can also be installed using `bundler`, by adding a line for it in your `Gemfile`.

```ruby
gem 'no-lorem', require: false
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
    -w, --deny-word WORD             Add word to deny list
    -C, --deny-constant CONSTANT     Add constant to deny list
```

Search for the words _lorem_ and _ipsum_ in the `app` directory and all its subdirectories.

```sh
$ no-lorem -w "lorem" -w "ipsum" app/
```

Search for the module "Faker" in any ruby file in the `app` directory and all its subdirectories. 

```sh
$ no-lorem -C Faker app/
```

Use a regular expression to search for URLs containing 'example.com'.

```sh
$ bin/no-lorem -w '/https?:\/\/example.com/' app/
```


## Using deny-lists

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
$ bin/no-lorem -c denylist.yaml .
```

If no configuration file is provided with the `-c` or `--config` option, **No-lorem** will try to load
the file `./.no-lorem.yaml` in the current directory and if that fails it will look for a file `~/.no-lorem.yaml`
in the user's home directory.
Finaly, if no configuration file is provided and no `-w` or `-C` options are specified, **No-lorem** stops and
displays an error message.

## Excluding files from the search

We can use the `--exclude` command line option to exclude a specific file or path from a search. 
For example to search through the `app/` directory but exclude everything in the `app/vendor` subdirectory
we can run the following command:

```sh
$ no-lorem -w "lorem" -w "ipsum" --exclude app/vendor app/
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

If **No-lorem** finds any of the specified words or constants it exists with a non-zero status code. If no 
matches are found the program exists with a 0 status code.


