=====================
Value Type in Kidy VM
=====================

.. contents::

Kidy is a dynamic-typed language, variables in Kidy have no type. A
variable can bind to any type of value. But in the VM, which is
written in C++ (a static-typed language), we need a type for the
*variable* -- ``KValue``.

Type tag
========

On 32-bit machine, ``KValue`` is a 32-bit value. The least 1 or more
bits are used to identify the type of the value. 

There are two articles discussed whether fixed length tag or variable
length tag is better and whether tag 0 or tag 1 should be used for
pointers. 

* `Ruby Internals: Why RUBY_FIXNUM_FLAG should be 0x00
  <http://kurtstephens.com/node/52>`_.
* `Parameterized Word Tagging in Latently-Typed Languages
  <http://kurtstephens.com/node/60>`_.

Kidy uses variable length tag and tag 1 for fixnums:

.. sourcecode:: text

  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxx1: Fixnum
  00000000 00000000 00000000 00001110: nil
  00000000 00000000 00000000 00011110: undef
  00000000 00000000 00000000 00101110: false
  00000000 00000000 00000000 00000110: true
  xxxxxxxx xxxxxxxx xxxxxxxx xxxxx010: Symbol
  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxx00: Object

In this design, ``nil``, ``false`` and ``undef`` share a common tail
``1110``. In Kidy, every value except those three are regards as
*true*. So a bool predicate can be very simple:

.. sourcecode:: c++

  inline bool is_true(KValue val) {
      return (val & 0xF) != 0xE;
  }
