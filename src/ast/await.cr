module Mint
  class Ast
    class Await < Node
      getter body

      def initialize(@from : Parser::Location,
                     @to : Parser::Location,
                     @file : Parser::File,
                     @body : Node)
      end
    end
  end
end