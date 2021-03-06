// Generated by CoffeeScript 1.7.1
(function() {
  var Configuration, DI, DIFactory, Database, Http, Mail, di, dir, expect, factory, path;

  expect = require('chai').expect;

  path = require('path');

  DI = require('../../../lib/DI');

  DIFactory = require('../../../DIFactory');

  Configuration = require('../../../Configuration');

  Http = require('../../data/Http');

  Database = require('../../data/MySql');

  Mail = require('../../data/Mail');

  dir = path.resolve(__dirname + '/../../data');

  di = null;

  factory = null;

  describe('DIFactory', function() {
    beforeEach(function() {
      factory = new DIFactory(dir + '/config.json');
      di = factory.create();
      return di.basePath = dir;
    });
    describe('#constructor()', function() {
      it('should resolve relative path to absolute path', function() {
        factory = new DIFactory('../../data/config.json');
        expect(factory.path).to.be.equal(dir + '/config.json');
        return expect(factory.create().parameters.language).to.be.equal('en');
      });
      it('should create di with custom config object', function() {
        var config;
        config = new Configuration;
        config.addConfig('../../data/config.json');
        config.addConfig('../../data/sections.json', 'local');
        factory = new DIFactory(config);
        di = factory.create();
        expect(di).to.be.an["instanceof"](DI);
        return expect(di.parameters.users.david).to.be.equal('divad');
      });
      it('should create database service from factory with list of parameters', function() {
        var db;
        factory = new DIFactory(dir + '/database.json');
        di = factory.create();
        db = di.get('database');
        expect(db).to.be.an["instanceof"](Database);
        return expect(db.parameters).to.be.eql({
          host: 'localhost',
          user: 'root',
          password: 'toor',
          database: 'application'
        });
      });
      return it('should create service with list of parameters', function() {
        var mail;
        factory = new DIFactory(dir + '/mail.json');
        di = factory.create();
        mail = di.get('mail');
        expect(mail).to.be.an["instanceof"](Mail);
        return expect(mail.setup).to.be.eql({
          type: 'SMTP',
          auth: {
            user: 'root',
            pass: 'toor'
          }
        });
      });
    });
    describe('#parameters', function() {
      return it('should contain all parameters', function() {
        return expect(di.parameters).to.be.eql({
          language: 'en',
          users: {
            david: '123456',
            admin: 'nimda'
          },
          database: {
            user: 'admin',
            password: 'nimda'
          }
        });
      });
    });
    describe('#getParameter()', function() {
      it('should throw an error if di object was not created from DIFactory', function() {
        di = new DI;
        return expect(function() {
          return di.getParameter('buf');
        }).to["throw"](Error, 'DI container was not created with DIFactory.');
      });
      return it('should return expanded parameter', function() {
        return expect(di.getParameter('database.password')).to.be.equal('nimda');
      });
    });
    return describe('#get()', function() {
      it('should load service defined with relative path', function() {
        factory = new DIFactory(dir + '/relative.json');
        di = factory.create();
        return expect(di.get('http')).to.be.an["instanceof"](Http);
      });
      it('should create services with derived arguments', function() {
        var application;
        factory = new DIFactory(dir + '/derivedArguments.json');
        di = factory.create();
        application = di.get('application');
        expect(application.data).to.be.equal('hello David');
        return expect(application.namespace).to.be["false"];
      });
      return it('should create service derived from other service', function() {
        factory = new DIFactory(dir + '/derivedService.json');
        di = factory.create();
        return expect(di.get('http')).to.be.an["instanceof"](Http);
      });
    });
  });

}).call(this);
