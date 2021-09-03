module LxChess
  class Terminal
    # ttycom.h : _IOR('t', 104, struct winsize)
    # ioccom.h :
    #   #define _IOC(inout, group, num, len) \
    #     (inout | ((len & IOCPARM_MASK) << 16) | ((group) << 8) | (num))
    # TODO : Figure out how to define this dynamically per system
    TIOCGWINSZ = 1074295912

    lib C
      struct Winsize
        rows : UInt16   # rows, in characters
        cols : UInt16   # columns, in characters
        width : UInt16  # horizontal size, pixels
        height : UInt16 # vertical size, pixels
      end

      fun ioctl(fd : Int32, request : UInt32, winsize : C::Winsize*) : Int32
    end

    def self.size
      C.ioctl(0, TIOCGWINSZ, out screen_size)
      screen_size
    end

    def initialize(@io = STDOUT)
    end
  end
end
