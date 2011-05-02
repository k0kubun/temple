module Temple
  module Mixins
    # @api private
    module CoreDispatcher
      def on_multi(*exps)
        [:multi, *exps.map {|exp| compile(exp) }]
      end

      def on_capture(name, exp)
        [:capture, name, compile(exp)]
      end
    end

    # @api private
    module EscapeDispatcher
      def on_escape(flag, exp)
        [:escape, flag, compile(exp)]
      end
    end

    # @api private
    module ControlFlowDispatcher
      def on_if(condition, *cases)
        [:if, condition, *cases.compact.map {|e| compile(e) }]
      end

      def on_case(arg, *cases)
        [:case, arg, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end

      def on_block(code, content)
        [:block, code, compile(content)]
      end

      def on_cond(*cases)
        [:cond, *cases.map {|condition, exp| [condition, compile(exp)] }]
      end
    end

    # @api private
    module Dispatcher
      include CoreDispatcher
      include EscapeDispatcher
      include ControlFlowDispatcher

      def self.included(base)
        base.class_eval { extend ClassMethods }
      end

      def call(exp)
        compile(exp)
      end

      def compile(exp)
        type, *args = exp
        method = "on_#{type}"
        if respond_to?(method)
          send(method, *args)
        else
          exp
        end
      end

      module ClassMethods
        def dispatch(*bases)
          bases.each do |base|
            class_eval %{def on_#{base}(type, *args)
              method = "on_#{base}_\#{type}"
              if respond_to?(method)
                send(method, *args)
              else
                [:#{base}, type, *args]
              end
            end}
          end
        end
      end
    end
  end
end
