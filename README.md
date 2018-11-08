# Emfrp

Pure Functional Reactive Programming Language for Small-Scale Embedded Systems

## Installation

Requirement
* Ruby2.0 or later (and it's Gem client)

### Using RubyGem

```
$ gem install emfrp
```

### From Source

Install Bundler if it is not installed.
```sh
$ gem install bundler
```

Clone this repository and install from the cloned source as follows.
```sh
$ cd emfrp
$ rake install
```

Some environments require that you have an administrator account to install.
```sh
$ sudo rake install
```

## Usage
Command-line-interpreter (REPL)
```sh
$ emfrpi
```

Compiler
```sh
$ emfrp [options] <src-file>
```

Options
* `--nomain` does not generate _main_ file
* `--cpp` generates `.cpp` instead of `.c`

See wiki for details.  
https://github.com/psg-titech/emfrp/wiki

## Sample Code

* [emfrp_samples](https://github.com/psg-titech/emfrp_samples)


## History
Originally developed by [Kensuke Sawada](https://github.com/sawaken)   
http://www.psg.c.titech.ac.jp/posts/2016-03-15-CROW2016.html
