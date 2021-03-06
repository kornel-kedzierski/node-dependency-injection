DI = require '/lib/DI'
Service = require '/lib/Service'

Application = require '/test/data/Application'
Http = require '/test/data/Http'

dir = '/test/data'

di = null

describe 'DI', ->

	beforeEach( ->
		di = new DI
	)

	describe 'defaults', ->

		it 'should be added di into services', ->
			expect(di.get('di')).to.be.equal(di)

		it 'should be added timer service', (done) ->
			timer = di.get('timer')
			expect(timer).to.have.keys(['setTimeout', 'setInterval', 'clearTimeout', 'clearInterval'])
			timer.setTimeout( ->
				done()
			, 100)

		it 'should be added window object service', ->
			expect(di.get('window')).to.be.equal(window)

		it 'should be added document object service', ->
			expect(di.get('document')).to.be.equal(window.document)

	describe '#addService()', ->

		it 'should return instance of new Service class from object', ->
			expect(di.addService('array', Array)).to.be.an.instanceof(Service)

		it 'should return instance of new Service class from path', ->
			expect(di.addService('app', "#{dir}/Application")).to.be.an.instanceof(Service)

		it 'should throw an error if you try to register service with reserved name', ->
			expect( -> di.addService('di', DI)).to.throw(Error, "DI: name 'di' is reserved by DI.")

		it 'should create service with null as arguments', ->
			di.addService('http', "#{dir}/Http")
			di.addService('app', "#{dir}/Application", [null])
			expect(di.get('app').array).to.not.exists

	describe '#tryCallArgument()', ->

		it 'should just return argument if it is not string', ->
			expect(di.tryCallArgument(new Date)).to.be.an.instanceof(Date)

		it 'should just return argument if it is not in right format', ->
			expect(di.tryCallArgument('hello word')).to.be.equal('hello word')

		it 'should return service by its name', ->
			di.addService('date', Date)
			expect(di.tryCallArgument('@date')).to.be.an.instanceof(Date)

		it 'should return service by its path', ->
			di.addService('callsite', 'callsite').setInstantiate(false)
			expect(di.tryCallArgument('$callsite')).to.be.equal(require('callsite'))

		it 'should return factory by its name', ->
			di.addService('date', Date)
			factory = di.tryCallArgument('factory:@date')
			expect(factory).to.be.an.instanceof(Function)
			expect(factory()).to.be.an.instanceof(Date)

		it 'should return factory by its path', ->
			di.addService('callsite', 'callsite').setInstantiate(false)
			factory = di.tryCallArgument('factory:$callsite')
			expect(factory).to.be.an.instanceof(Function)
			expect(factory()).to.be.equal(require('callsite'))

		it 'should return result from method in service', ->
			di.addService('obj',
				doSomething: -> return 'hello'
			).setInstantiate(false)
			expect(di.tryCallArgument('@obj::doSomething')).to.be.equal('hello')

		it 'should return result from method with arguments', ->
			di.addService('obj',
				doSomething: (one, two, three) -> return one + two + three
			).setInstantiate(false)
			expect(di.tryCallArgument('@obj::doSomething("hello", " ", "word")')).to.be.equal('hello word')

		it 'should return result from method with arguments with sub calls to di', ->
			di.addService('obj',
				complete: -> {callMe: (greetings, name) -> return greetings + ' ' + name}
			).setInstantiate(false)
			expect(di.tryCallArgument('@obj::complete::callMe("hello", "David")')).to.be.equal('hello David')

	describe '#createInstance()', ->

		beforeEach( ->
			di.addService('array', Array)
			di.addService('http', Http)
		)

		it 'should return new instance of Application with all dependencies', ->
			app = di.createInstance(Application)
			expect(app).to.be.an.instanceof(Application)
			expect(app.array).to.be.an.instanceof(Array)
			expect(app.http).to.not.exists

		it 'should throw an error when service to inject does not exists', ->
			delete di.services.http
			app = di.createInstance(Application)
			expect( -> di.inject(app.setHttp, [], app)).to.throw(Error, "DI: Service 'http' was not found.")

	describe '#findDefinitionByName()', ->

		it 'should return definition of Array service', ->
			di.addService('array', Array)
			expect(di.findDefinitionByName('array')).to.be.an.instanceof(Service)

		it 'should throw an error if service is not registered', ->
			expect( -> di.findDefinitionByName('array')).to.throw(Error, "DI: Service 'array' was not found.")

	describe 'Loaders', ->

		beforeEach( ->
			di.addService('array', Array)
			di.addService('http', Http)
			di.addService('info', ['hello'])
			.setInstantiate(false)
			di.addService('noArray', ['not this one'])
			.setInstantiate(false)
			.setAutowired(false)
			di.addService('application', Application)
			.addSetup('prepare', ['simq', '...'])
		)

		describe '#get()', ->

			it 'should return instance of Application with all dependencies', ->
				app = di.get('application')
				expect(app).to.be.an.instanceof(Application)
				expect(app.namespace).to.be.equal('simq')
				expect(app.array).to.be.eql([])
				expect(app.http).to.not.exists

			it 'should return always the same instance of Application', ->
				expect(di.get('application')).to.be.equal(di.get('application'))

			it 'should add service from node_modules', ->
				di.addService('callsite', 'callsite').setInstantiate(false)
				expect(di.get('callsite')).to.be.equal(require('callsite'))

			it 'should return info array without instantiating it', ->
				expect(di.get('info')).to.be.eql(['hello'])

			it 'should not set services which are not autowired', ->
				di.findDefinitionByName('application')
				.addSetup('setData')
				expect( -> di.get('application')).to.throw(Error, "DI: Service 'noArray' in not autowired.")

			it 'should autowire di container into Application instance', ->
				di.findDefinitionByName('application')
				.addSetup('setDi')
				expect(di.get('application').di).to.be.equal(di)

			it 'should autowire di container factory into Application instance', ->
				di.findDefinitionByName('application')
				.addSetup('setDiFactory')
				factory = di.get('application').diFactory
				expect(factory).to.be.an.instanceof(Function)
				expect(factory()).to.be.equal(di)

			it 'should set info property directly', ->
				di.findDefinitionByName('application')
				.addSetup('info', 'by property')
				expect(di.get('application').info).to.be.equal('by property')

			it 'should throw an error if circular reference was found', ->
				di.addService('first', (second) ->)
				di.addService('second', (first) ->)
				expect( -> di.get('first')).to.throw(Error, 'Circular reference detected for services: first, second.')

			it 'should throw an error with simple circular reference', ->
				di.addService('first', (first) ->)
				expect( -> di.get('first')).to.throw(Error, 'Circular reference detected for service: first.')

			it 'should throw an error with advanced circular reference', ->
				di.addService('first', (second) ->)
				di.addService('second', (third) ->)
				di.addService('third', (fourth) ->)
				di.addService('fourth', (first) ->)
				expect( -> di.get('first')).to.throw(Error, 'Circular reference detected for services: first, second, third, fourth.')

		describe '#getByPath()', ->

			it 'should return service by require path', ->
				di.addService('app', "#{dir}/Application")
				expect(di.getByPath("#{dir}/Application")).to.be.an.instanceof(Application)

			it 'should return null for not auto required services', ->
				di.addService('info', ['hello']).setInstantiate(false)
				expect(di.getByPath('info')).to.not.exists

		describe '#create()', ->

			it 'should return always new instance of Application', ->
				expect(di.create('application')).to.not.be.equal(di.create('application'))

		describe '#getFactory()', ->

			it 'should return callable factory for Application', ->
				factory = di.getFactory('application')
				expect(factory).to.be.an.instanceof(Function)
				expect(factory()).to.be.an.instanceof(Application)

		describe '#inject()', ->

			it 'should inject some service into annonymous function', (done) ->
				di.addService('array', Array)
				di.inject( (array) ->
					expect(array).to.be.eql([])
					done()
				)

			it 'should throw an error if inject method is not called on function', ->
				expect( -> di.inject('')).to.throw(Error, "DI: Inject method can be called only on functions.")