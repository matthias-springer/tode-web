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
      attach_function "GciI64ToOop", [:int], :int
      attach_function "GciInit", [], :bool
      attach_function "GciLogin", [:string, :string], :bool
      attach_function "GciOopToI64", [:int], :int
      attach_function "GciSetNet", [:string, :string, :string, :string], :void
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

