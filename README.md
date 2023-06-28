Never leave placeholder text like _Lorem ipsum dolor sit amet..._ slip into production. 

**No-lorem** is a tool that can search through ruby code for undesired words in strings or constants 
identifying undesired libraries. **No-lorem** cam also search `.erb` or `.slim` files for undesired words or
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

If **No-lorem** does not find any of the searched words or constants 

## Using deny-lists

Instead of providing words or constants as command line arguments, it is possible to create as denylist 
as a YAML file, which is then provided to **No-lorem**.

The 3 examples described above can be summarized in the following YAML denylist:

```yaml
deny:
  words:
    - lorem 
    - ipsum 
    - /https?:\/\/example.com/
  constants:
    - Faker
```

Assuming this YAML denylist is stored in a file named `denylist.yaml`, we can search our `app/` directory
with the following command:

```sh
$ bin/no-lorem -c no-lorem.sample.yaml .
```

## Status code

If **No-lorem** find searched words or constants it exists with a non-zero status code. If no 
matches are found the program exists with a 0 status code.


