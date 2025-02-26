import cli as cli-pkg
import cli.ui as cli-pkg
import encoding.json
import monitor

class TestExit:

class TestUi extends cli-pkg.Ui:
  stdout/string := ""
  stderr/string := ""
  quiet_/bool
  json_/bool
  signal/monitor.Signal := monitor.Signal

  constructor --level/int=cli-pkg.Ui.NORMAL-LEVEL --quiet/bool=true --json/bool=false:
    quiet_ = quiet
    json_ = json
    printer := create-printer_ --json=json
    super --printer=printer --level=level
    (printer as TestPrinter).set-test-ui_ this

  static create-printer_ --json/bool -> cli-pkg.Printer:
    if json: return TestJsonPrinter
    return TestHumanPrinter

  abort:
    throw TestExit

class TestHumanPrinter extends cli-pkg.HumanPrinter implements TestPrinter:
  test-ui_/TestUi? := null

  print_ str/string:
    if not test-ui_.quiet_: super str
    test-ui_.stdout += "$str\n"
    test-ui_.signal.raise

  set-test-ui_ test-ui/TestUi:
    test-ui_ = test-ui

class TestJsonPrinter extends cli-pkg.JsonPrinter implements TestPrinter:
  test-ui_/TestUi? := null

  print_ str/string:
    if not test-ui_.quiet_: super str
    test-ui_.stderr += "$str\n"
    test-ui_.signal.raise

  emit-structured --kind/int data:
    test-ui_.stdout += json.stringify data
    test-ui_.signal.raise

  set-test-ui_ test-ui/TestUi:
    test-ui_ = test-ui

interface TestPrinter:
  set-test-ui_ test-ui/TestUi?

class TestCli implements cli-pkg.Cli:
  name/string
  ui/TestUi

  constructor --.name/string="test" --quiet/bool=true:
    ui=(TestUi --quiet=quiet)

  cache -> cli-pkg.Cache:
    unreachable

  config -> cli-pkg.Config:
    unreachable

  with --name=null --cache=null --config=null --ui=null:
    unreachable

