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

      attach_function "GciExecuteStr", [:string, :int], :int
      attach_function "GciExecuteStr_", [:string, :int, :int], :int
      attach_function "GciFetchChars_", [:int, :int, :string, :int], :int
      attach_function "GciFetchSize_", [:int], :int
      attach_function "GciGetSessionId", [], :int
      attach_function "GciI64ToOop", [:int], :int
      attach_function "GciInit", [], :bool
      attach_function "GciLogin", [:string, :string], :bool
      attach_function "GciLogout", [], :void
      attach_function "GciOopToI64", [:int], :int
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
      puts "getting size"
      size = self.GciFetchSize_(obj) + 1
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
   
    def gci_set_session_id(session_id)
      self.GciSetSessionId(session_id)
    end

    def gci_version
      self.GciVersion
    end

    private

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

