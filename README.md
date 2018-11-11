# Emfrp

Pure Functional Reactive Programming Language for Small-Scale Embedded Systems

## Installation

Requirement
* Ruby 2.0 or later (and it's Gem client)
* C (or C++) compiler for your favorite target platform

### via RubyGems

Just type the following command.
```
$ gem install emfrp
```
You are all set. Enjoy!

### from Source

Install `Bundler` if it is not installed.
```sh
$ gem install bundler
```

Clone this repository and install from the cloned source as follows.
```sh
$ cd emfrp
$ rake install
```

***NOTE***
Some environments require that you need to be an administrator to perform `gem install` or `rake install`.

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
* `--nomain`  
  does not generate _main_ file
* `--cpp`  
  generates `.cpp` instead of `.c`

See wiki for details.  
https://github.com/psg-titech/emfrp/wiki

## Sample Code

* [emfrp_samples](https://github.com/psg-titech/emfrp_samples)


## History
Originally developed by [Kensuke Sawada](https://github.com/sawaken)   
* [Paper](http://www.psg.c.titech.ac.jp/posts/2016-03-15-CROW2016.html)
