
describe("Space.messaging.Controller - command handling", function () {

  beforeEach(function() {
    this.testCommand = new MyApp.TestCommand({
      targetId: '123',
      value: new TestValue({ value: 'test' })
    });
    this.anotherCommand = new MyApp.AnotherCommand({ targetId: '123' });
  });

  it("sets up context bound command handlers", function () {

    var commandHandlerSpy = sinon.spy();
    var anotherCommandHandler = sinon.spy();

    // Define a controller that uses the `events` API to declare handlers
    MyApp.TestController = Space.messaging.Controller.extend('TestController', {
      commandHandlers: function() {
        return [{
          'MyApp.TestCommand': commandHandlerSpy,
          'MyApp.AnotherCommand': anotherCommandHandler
        }];
      }
    });

    // Integrate the controller in our test app
    var ControllerTestApp = MyApp.extend('ControllerTestApp', {
      Singletons: ['MyApp.TestController']
    });

    // Startup app and send event through the bus
    var app = new ControllerTestApp();
    var controller = app.injector.get('MyApp.TestController');
    app.start();
    app.commandBus.send(this.testCommand);
    app.commandBus.send(this.anotherCommand);

    // Expect that the controller routed the events correctly
    expect(commandHandlerSpy).to.have.been.calledWithExactly(this.testCommand);
    expect(commandHandlerSpy).to.have.been.calledOn(controller);
    expect(anotherCommandHandler).to.have.been.calledWithExactly(this.anotherCommand);
    expect(anotherCommandHandler).to.have.been.calledOn(controller);

  });
});
