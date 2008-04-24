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

On 32-bit machine, ``KValue`` is a 32-bit value. The least 2 bits are
used to identify the type of the value. We can represent 4 types by
the 2 bits:

* Fixnum
* Special Constants
* Symbol
* Object

I followed some suggestions by Kurt Stephens on his blog post `Ruby
Internals: Why RUBY_FIXNUM_FLAG should be 0x00
<http://kurtstephens.com/node/52>`_. Here's how the bits look like on
a 32-bit machine:

.. sourcecode:: text

  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxx00: Fixnum
  00000000 00000000 00000000 00000111: nil
  00000000 00000000 00000000 00010111: undef
  00000000 00000000 00000000 00001111: false
  00000000 00000000 00000000 00001011: true
  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxx01: Symbol
  xxxxxxxx xxxxxxxx xxxxxxxx xxxxxx10: Object

Here's some advantages of this design.

Fixnum operations cheap
-----------------------

When there are **no overflow**, some operations for Fixnum can be very
cheap:

=========== ============================= =====================
 Operation   Original form                 Optimized form
=========== ============================= =====================
plus        ``((a>>2)+(b>>2)) << 2``      ``a+b``
minus       ``((a>>2)-(b>>2)) << 2``      ``a-b``
multiply    ``((a>>2)*(b>>2)) << 2``      ``(a>>2)*b``
divide      ``((a>>2)*(b>>2)) << 2``      ``(a/b) << 2``
=========== ============================= =====================

Pointer access cheap
--------------------

Compilers and dynamic memory allocators will align allocations to word
boundaries for performance reasons. So the least two bits of a pointer
will always be zero (*note this is not always portable*) and can be
safely used for type tagging.

Here I take the examples from Kurt Stephens' blog:

.. sourcecode:: c
  
  #define RBASIC(X) ((struct RBasic *)((X) - 2))

``- 3`` is used instead of ``& 3`` here is because this can be used
for optimization by compiler. The compiler converts
``pointer->member`` expression into an offset from an address. For
example, if the ``RBasic`` struct is deined like this:

.. sourcecode:: c

  struct RBasic {
      VALUE flags; /* struct offset: + 0 */
      VALUE klass; /* struct offset: + 4 */
  };

Then compiler will convert ``RBASIC(X)->klass`` to ``RBASIC(X) + 4``
which is really ``((X) - 2) + 4``. This can be compiled as ``X + 2``
directly by the compiler.

Boolean predict cheap
---------------------

In Kidy, all values except ``nil``, ``false`` and ``undef`` are
regards as *true*. If you notice the common shape of the three
particular values, you'll see that boolean predict can be very simple:

.. sourcecode:: c++

  inline bool is_true(KValue val) {
      return (val & 0x7) != 0x7;
  }
