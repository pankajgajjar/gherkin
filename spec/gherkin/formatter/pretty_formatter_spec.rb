# encoding: utf-8
require 'spec_helper'
require 'gherkin/formatter/pretty_formatter'
require 'gherkin/formatter/monochrome_io'
require 'gherkin/formatter/argument'
require 'gherkin/formatter/model'
require 'gherkin/listener/formatter_listener'
require 'stringio'

module Gherkin
  module Formatter
    describe PrettyFormatter do
      include Colors

      def assert_io(s)
        actual = @io.string
        actual.should == s
      end
      
      def assert_pretty(input, output=input)
        [true, false].each do |force_ruby|
          io = MonochromeIO.new(StringIO.new)
          pf = Gherkin::Formatter::PrettyFormatter.new(io)
          parser = Gherkin::Parser::Parser.new(pf, true, "root", force_ruby)
          parser.parse(input, "test.feature", 0)
          actual = io.string
          actual.should == output
        end
      end

      def result(status, error_message, arguments, stepdef_location)
        Model::Result.new(status, error_message, arguments, stepdef_location)
      end

      before do
        @io = StringIO.new
        @l = Gherkin::Formatter::PrettyFormatter.new(@io)
      end

      it "should print comments when scenario is longer" do
        @l.uri("features/foo.feature")
        @l.feature(Model::Feature.new([], [], "Feature", "Hello", "World", 1))
        step1 = Model::Step.new([], "Given ", "some stuff", 5, nil, result('passed', nil, [], "features/step_definitions/bar.rb:56"))
        step2 = Model::Step.new([], "When ", "foo", 6, nil, result('passed', nil, [], "features/step_definitions/bar.rb:96"))
        @l.steps([step1, step2])
        @l.scenario(Model::Scenario.new([], [], "Scenario", "The scenario", "", 4))
        @l.step(step1)
        @l.step(step2)

        assert_io(%{Feature: Hello
  World

  Scenario: The scenario #{grey('# features/foo.feature:4')}
    #{green('Given ')}#{green('some stuff')}     #{grey('# features/step_definitions/bar.rb:56')}
    #{green('When ')}#{green('foo')}             #{grey('# features/step_definitions/bar.rb:96')}
})
      end

      it "should print comments when step is longer" do
        @l.uri("features/foo.feature")
        @l.feature(Model::Feature.new([], [], "Feature", "Hello", "World", 1))
        step = Model::Step.new([], "Given ", "some stuff that is longer", 5, nil, result('passed', nil, [], "features/step_definitions/bar.rb:56"))
        @l.steps([step])
        @l.scenario(Model::Scenario.new([], [], "Scenario", "The scenario", "", 4))
        @l.step(step)

        assert_io(%{Feature: Hello
  World

  Scenario: The scenario            #{grey('# features/foo.feature:4')}
    #{green('Given ')}#{green('some stuff that is longer')} #{grey('# features/step_definitions/bar.rb:56')}
})
      end

      it "should highlight arguments for regular steps" do
        step = Model::Step.new([], "Given ", "I have 999 cukes in my belly", 3, nil, result('passed', nil, [Gherkin::Formatter::Argument.new(7, '999')], nil))
        @l.steps([step])
        @l.step(step)
        assert_io("    #{green('Given ')}#{green('I have ')}#{green(bold('999'))}#{green(' cukes in my belly')}\n")
      end

      it "should prettify scenario" do
        assert_pretty(%{Feature: Feature Description
  Some preamble

  Scenario: Scenario Description
    description has multiple lines

    Given there is a step
      """
      with
        pystrings
      """
    And there is another step
      | æ   | \\|o |
      | \\|a | ø\\\\ |
    Then we will see steps
})
      end


      it "should prettify scenario outline with table" do
        assert_pretty(%{# A feature comment
@foo
Feature: Feature Description
  Some preamble
  on several
  lines

  # A Scenario Outline comment
  @bar
  Scenario Outline: Scenario Ouline Description
    Given there is a
      """
      string with <foo>
      """
    And a table with
      | <bar> |
      | <baz> |

    @zap @boing
    Examples: Examples Description
      | foo    | bar  | baz         |
      | Banana | I    | am hungry   |
      | Beer   | You  | are thirsty |
      | Bed    | They | are tired   |
})
      end

      it "should preserve tabs" do
        assert_pretty(IO.read(File.dirname(__FILE__) + '/tabs.feature'), IO.read(File.dirname(__FILE__) + '/spaces.feature'))
      end

      it "should escape backslashes and pipes" do
        io = StringIO.new
        l = Gherkin::Formatter::PrettyFormatter.new(io)
        l.__send__(:table, [Gherkin::Formatter::Model::Row.new([], ['|', '\\'], nil)])
        io.string.should == '      | \\| | \\\\ |' + "\n"
      end
    end
  end
end
