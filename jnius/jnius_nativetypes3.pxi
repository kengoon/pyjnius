
cdef python_op(int op, object a, object b):
    if op == 0:
        return a < b
    elif op == 1:
        return a <= b
    elif op == 2:
        return a == b
    elif op == 3:
        return a >= b
    elif op == 4:
        return a > b
    elif op == 5:
        return a != b

cdef class ByteArray:
    cdef LocalRef _jobject
    cdef long _size
    cdef unsigned char *_buf
    cdef unsigned char[:] _arr
    cdef public bint _JNIUS_PASS_BY_VALUE

    def __cinit__(self):
        self._size = 0
        self._buf = NULL
        self._arr = None
        self._JNIUS_PASS_BY_VALUE = False

    def __dealloc__(self):
        cdef JNIEnv *j_env
        if self._buf != NULL:
            j_env = get_jnienv()
            j_env[0].ReleaseByteArrayElements(
                j_env, self._jobject.obj, <jbyte *>self._buf, 0)
            self._buf = NULL
        self._jobject = None

    cdef void set_buffer(self, JNIEnv *env, jobject obj, long size, jbyte *buf):
        if self._buf != NULL:
            raise Exception('Cannot call set_buffer() twice.')
        self._jobject = LocalRef()
        self._jobject.create(env, obj)
        self._size = size
        self._buf = <unsigned char *><signed char *>buf
        if size:
            self._arr = <unsigned char[:size]>self._buf

    def __str__(self):
        return '<ByteArray size={} at 0x{}>'.format(
                self._size, id(self))

    def __len__(self):
        return self._size

    def __getitem__(self, index):
        cdef long xx
        if isinstance(index, slice):
            val = []
            if self._size:
                (start, stop, step) = index.indices(len(self._arr))
                for x in range(start, stop, step):
                    xx = x
                    val.append(self._arr[xx])
            return val
        else:
            xx = index
            return self._arr[xx]

    def __setitem__(self, index, val):
        cdef long xx
        cdef int x
        # cdef long jj
        cdef unsigned char *vals
        cdef long start
        cdef long stop
        cdef long step
        if isinstance(index, slice):
            vals = val
            if self._size:
                (start, stop, step) = index.indices(self._size)
                # the following is faster than `range(start, stop, step)`
                for x in range(((step - 1) + stop - start) // step):
                    xx = x
                    self._arr[start + xx * step] = vals[xx]
        else:
            xx = index
            self._arr[xx] = val

    def __richcmp__(self, other, op):
        cdef ByteArray b_other
        if isinstance(other, (list, tuple)):
            return python_op(op, self.tolist(), other)
        elif isinstance(other, ByteArray):
            b_other = other
            return python_op(op, self.tostring(), other.tostring())
        else:
            return False

    def tolist(self):
        return list(self[:])

    def tostring(self):
        return self._buf[:self._size]
