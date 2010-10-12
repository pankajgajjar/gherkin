# encoding: utf-8
require 'spec_helper'
require 'gherkin/formatter/step_printer'
require 'gherkin/formatter/argument'
require 'stringio'

module Gherkin
  module Formatter
    class BracketStepFormat
      def write_text(io, text)
        io.write("(#{text})")
      end

      def write_arg(io, arg)
        io.write("[#{arg}]")
      end
    end
    
    describe StepPrinter do
      before do
        @io = StringIO.new
        @p = StepPrinter.new
        @f = BracketStepFormat.new
      end

      it "should replace 0 args" do
        @p.write_step(@io, @f, "I have 10 cukes", [])
        @io.string.should == "(I have 10 cukes)"
      end

      it "should replace 1 arg" do
        @p.write_step(@io, @f, "I have 10 cukes", [Argument.new(7, '10')])
        @io.string.should == "(I have )[10]( cukes)"
      end
      
      it "should replace 1 unicode arg" do
        @p.write_step(@io, @f, "I hæve øæ cåkes", [Argument.new(7, 'øæ')])
        @io.string.should == "(I hæve )[øæ]( cåkes)"
      end
      
      it "should replace 2 args" do
        @p.write_step(@io, @f, "I have 10 yellow cukes in my belly", [Argument.new(7, '10'), Argument.new(17, 'cukes')])
        @io.string.should == "(I have )[10]( yellow )[cukes]( in my belly)"
      end

      it "should replace 2 unicode args" do
        @p.write_step(@io, @f, "Æslåk likes æøå", [Argument.new(0, 'Æslåk'), Argument.new(12, 'æøå')])
        @io.string.should == "[Æslåk]( likes )[æøå]"
      end
    end
  end
end
