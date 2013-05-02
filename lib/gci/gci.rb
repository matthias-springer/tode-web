require "ffi"

module GCI
  extend FFI::Library
  
  OOP_NIL = 20

  class << self
    def gci_library_name
      @gci_library_name ||= "./libgcirpc-3.1.0.2-64.so"
    end
    
    def gem_host
      @gem_host ||= "localhost"
    end

    def gem_task
      @gem_task ||= "gemnetobject"
    end

    def net_ldi
      @net_ldi ||= 50378
    end

    def os_password
      @os_password ||= ""
    end

    def os_user
      @os_user ||= ""
    end

    def password
      @password ||= "swordfish"
    end

    def stone_host
      @stone_host ||= "localhost"
    end
  
    def stone_name
      @stone_name ||= "maglev"
    end

    def user_id
      @user_id ||= "DataCurator"
    end

    attr_writer :gci_library_name
    attr_writer :gem_host
    attr_writer :gem_task
    attr_writer :net_ldi
    attr_writer :os_password
    attr_writer :os_user
    attr_writer :password
    attr_writer :stone_host
    attr_writer :stone_name
    attr_writer :user_id

    def init_ffi
      ffi_lib gci_library_name
      ffi_convention :stdcall

      attach_function "GciErr", [GciErrSType.ptr], :bool
      attach_function "GciExecuteStr", [:string, :int], :int
      attach_function "GciExecuteStr_", [:string, :int, :int], :int
      attach_function "GciFetchChars_", [:int, :int, :string, :int], :int
      attach_function "GciFetchSize_", [:int], :int
      attach_function "GciGetSessionId", [], :int
      attach_function "GciI64ToOop", [:int], :int
      attach_function "GciInit", [], :bool
      attach_function "GciLogin", [:string, :string], :bool
      attach_function "GciLogout", [], :void
      attach_function "GciNbEnd", [GciOopPtrRefType.ptr], :int
      attach_function "GciNbExecuteStr_", [:string, :int, :int], :int
      attach_function "GciNewString", [:string], :int
      attach_function "GciOopToI64", [:int], :int
      attach_function "GciPerform", [:int, :string, :pointer, :int], :int
      attach_function "GciSetNet", [:string, :string, :string, :string], :void
      attach_function "GciSetSessionId", [:int], :void
      attach_function "GciVersion", [], :int
    end  

    def gci_execute_str(obj, oop, env_id = nil)
      if env_id == nil
        return self.GciExecuteStr(obj, oop)
      else
        return self.GciExecuteStr_(obj, oop, env_id)
      end
    end

    def gci_fetch_string(obj)
      puts "getting size for #{obj}"
      size = self.GciFetchSize_(obj) + 1
      puts "size: #{size}"
      string_ptr = " " * size

      puts "reading #{size} bytes"
      size_read = self.GciFetchChars_(obj, 1, string_ptr, size)
      if size_read + 1 == size
        # strip null byte
        return string_ptr[0..-2]
      else
        raise RuntimeError, "GciFetchChars() failed. Read #{size_read} instead of #{size} bytes."
      end
    end
    
    def gci_long_to_oop(integer)
      GCI.GciI64ToOop(integer)
    end

    def gci_nb_execute_string(string, oop, env_id)
      GCI.GciNbExecuteStr_(string, oop, env_id)
    end

    def gci_new_string(string)
      GCI.GciNewString(string)
    end

    def gci_get_session_id
      #TODO: think about this

      if @logged_in
        return self.GciGetSessionId
      else
        return 0
      end
    end

    def gci_logout
      self.GciLogout if @logged_in
      @logged_in = false
    end

    def gci_login
      if not self.GciInit
        raise RuntimeError, "GciInit failed."
      end

      self.GciSetNet(stone_nrs, os_user, os_password, gem_nrs)

      if not self.GciLogin(user_id, password)
        raise RuntimeError, "GciLogin failed."
      end

      test_gci_link
      @logged_in = true
    end
    
    def gci_nb_end
      progress = nil
      result = nil

      ptr = GciOopPtrRefType.new
      progress = self.GciNbEnd(ptr)
      result = ptr.oop if progress == 2

      return [progress, result]
    end

    def poll_for_result
      poll_result = [0, nil]

      while (poll_result[0] != 2)
        poll_result = gci_nb_end()
        sleep 0.1 if poll_result[0] != 2
      end

      return poll_result[1]
    end

    def gci_perform(receiver, selector, arguments)
      args = prepare_arguments(arguments)
      result = nil

      FFI::MemoryPointer.new(:int, args.length) do |p_args|
        p_args.write_array_of_int(args)
        result = self.GciPerform(receiver, selector, p_args, args.length)
      end

      return result
    end
   
    def gci_set_session_id(session_id)
      self.GciSetSessionId(session_id)
    end

    def gci_version
      self.GciVersion
    end

    class GciOopRefType < FFI::Struct
      layout :ptr_x, :int,
        :ptr_y, :int

      def oop
        oop_for_pointer(self[:ptr_x], self[:ptr_y])
      end

      private

      def oop_for_pointer(x, y)
        if y == 0
          return x
        else
          return (y << 32) + x
        end
      end
    end

    class GciOopPtrRefType < FFI::Struct
      layout :ptr, GciOopRefType.ptr

      def oop
        self[:ptr].oop
      end
    end

    class GciErrSType < FFI::Struct
      GCI_MAX_ERR_ARGS = 10
      GCI_ERR_STR_SIZE = 1024
      GCI_ERR_reasonSize = GCI_ERR_STR_SIZE

      layout :category, GciOopRefType,
        :context, GciOopRefType,
        :exception_obj, GciOopRefType,
        :args, [:uint, GCI_MAX_ERR_ARGS * 2],
        :number, :int,
        :arg_count, :int,
        :fatal, :uchar,
        :message, [:char, GCI_ERR_STR_SIZE + 1],
        :reason, [:char, GCI_ERR_reasonSize + 1]
    end

    def gci_err
      err_obj = GciErrSType.new
      result = self.GciErr(err_obj)

      args = []
      (0..GciErrSType::GCI_MAX_ERR_ARGS-1).each do |arg_idx|
        args[arg_idx] = oop_for_pointer(err_obj[:args][arg_idx*2], err_obj[:args][arg_idx*2 + 1])
      end

      return {:result => result,
        :category => err_obj[:category].oop,
        :context => err_obj[:context].oop,
        :exceptionObj => err_obj[:exception_obj].oop,
        :args => args,
        :number => err_obj[:number],
        :argCount => err_obj[:arg_count],
        :fatal => err_obj[:fatal],
        :message => err_obj[:message].to_ptr.read_string,
        :reason => err_obj[:reason].to_ptr.read_string}
    end

    private

    def oop_for_pointer(x, y)
      if y == 0
        return x
      else
        return (y << 32) + x
      end
    end

    def prepare_arguments(arguments)
      puts "prepare_arguments #{arguments}"

      args = []
      (0..arguments.length - 1).each do |i|
        args.push(arguments[i.to_s.to_sym])
      end
      
      puts "args: #{args}"

      args.collect do |arg|
        type = arg["type"]
        value = arg["value"]
        puts "type: #{type}    value: #{value}"

        case type
          when "oop"
            Integer(value)
          when "string"
            self.gci_new_string(value)
          when "integer"
            self.gci_long_to_oop(value)
          when "float"
            raise Exception, "float not supported yet"
          else
            raise Exception, "unknown data type #{type}"
        end
      end
    end
    
    def test_gci_link
      result = self.GciExecuteStr("1 + 2", OOP_NIL)

      if self.GciOopToI64(result) != 3
        raise RuntimeError, "GCI link not working properly."
      end
    end
     
    def gem_nrs
      "!tcp@#{gem_host}#netldi:#{net_ldi}#task!#{gem_task}"
    end

    def stone_nrs
      "!tcp@#{stone_host}#server!#{stone_name}"
    end
  end
end

