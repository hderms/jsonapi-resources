require File.expand_path('../../../test_helper', __FILE__)
require File.expand_path('../../../fixtures/active_record', __FILE__)

require 'jsonapi/operation'
require 'jsonapi/operation_result'
require 'jsonapi/operations_processor'

class TestOperationsProcessor < JSONAPI::OperationsProcessor
  before_operation :log_before_operation

  after_operation :log_after_operation

  around_operation :log_around_operation

  def log_before_operation
    msg = "Before Operation"
    # puts msg
  end

  def log_around_operation
    msg = "Starting... #{@operation.class.name}"
    # puts msg
    yield
    msg = "... Finishing #{@operation.class.name}"
    # puts msg
  end

  def log_after_operation
    msg = "After Operation"
    # puts msg
  end

  before_operations :log_before_operations

  after_operations :log_after_operations

  around_operations :log_around_operations

  def log_before_operations
    msg = "Before #{@operations.count} Operation(s)"
    # puts msg
  end

  def log_around_operations
    msg = "Starting #{@operations.count} Operation(s)..."
    # puts msg
    yield
    msg = "...Finishing Up Operations"
    # puts msg
  end

  def log_after_operations
    msg =  "After Operations"
    # puts msg
  end
end

class OperationsProcessorTest < MiniTest::Unit::TestCase
  def setup
    betax = Planet.find(5)
    betay = Planet.find(6)
    betaz = Planet.find(7)
    unknown = PlanetType.find(5)
  end

  def test_create_single_resource
    op = TestOperationsProcessor.new()

    count = Planet.count

    operations = [
      JSONAPI::CreateResourceOperation.new(PlanetResource, {attributes: {'name' => 'earth', 'description' => 'The best planet ever.'}})
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_kind_of(Array, results)
    assert_kind_of(JSONAPI::OperationResult, results[0])
    assert_equal(:created, results[0].code)
    assert_equal(results.size, 1)
    assert_equal(Planet.count, count + 1)
  end

  def test_create_multiple_resources
    op = JSONAPI::OperationsProcessor.new()

    count = Planet.count

    operations = [
      JSONAPI::CreateResourceOperation.new(PlanetResource, {attributes: {'name' => 'earth', 'description' => 'The best planet for life.'}}),
      JSONAPI::CreateResourceOperation.new(PlanetResource, {attributes: {'name' => 'mars', 'description' => 'The red planet.'}}),
      JSONAPI::CreateResourceOperation.new(PlanetResource, {attributes: {'name' => 'venus', 'description' => 'A very hot planet.'}})
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_kind_of(Array, results)
    assert_equal(results.size, 3)
    assert_equal(Planet.count, count + 3)
  end

  def test_replace_has_one_association
    op = JSONAPI::OperationsProcessor.new()

    saturn = Planet.find(1)
    gas_giant = PlanetType.find(1)
    planetoid = PlanetType.find(2)
    assert_equal(saturn.planet_type_id, planetoid.id)

    operations = [
      JSONAPI::ReplaceHasOneAssociationOperation.new(PlanetResource, saturn.id, :planet_type, gas_giant.id)
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_kind_of(Array, results)
    assert_kind_of(JSONAPI::OperationResult, results[0])
    assert_equal(:no_content, results[0].code)

    saturn.reload
    assert_equal(saturn.planet_type_id, gas_giant.id)

    # Reset
    operations = [
      JSONAPI::ReplaceHasOneAssociationOperation.new(PlanetResource, saturn.id, :planet_type, 5)
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)
    saturn.reload
    assert_equal(saturn.planet_type_id, 5)
  end

  def test_create_has_many_association
    op = JSONAPI::OperationsProcessor.new()

    betax = Planet.find(5)
    betay = Planet.find(6)
    betaz = Planet.find(7)
    gas_giant = PlanetType.find(1)
    unknown = PlanetType.find(5)
    betax.planet_type_id = unknown.id
    betay.planet_type_id = unknown.id
    betaz.planet_type_id = unknown.id
    betax.save!
    betay.save!
    betaz.save!

    operations = [
      JSONAPI::CreateHasManyAssociationOperation.new(PlanetTypeResource, gas_giant.id, :planets, [betax.id, betay.id, betaz.id])
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    betax.reload
    betay.reload
    betaz.reload

    assert_equal(betax.planet_type_id, gas_giant.id)
    assert_equal(betay.planet_type_id, gas_giant.id)
    assert_equal(betaz.planet_type_id, gas_giant.id)

    #   Reset
    betax.planet_type_id = unknown.id
    betay.planet_type_id = unknown.id
    betaz.planet_type_id = unknown.id
    betax.save!
    betay.save!
    betaz.save!
  end

  def test_replace_has_many_association
    op = JSONAPI::OperationsProcessor.new()

    betax = Planet.find(5)
    betay = Planet.find(6)
    betaz = Planet.find(7)
    gas_giant = PlanetType.find(1)
    unknown = PlanetType.find(5)
    betax.planet_type_id = unknown.id
    betay.planet_type_id = unknown.id
    betaz.planet_type_id = unknown.id
    betax.save!
    betay.save!
    betaz.save!

    operations = [
      JSONAPI::ReplaceHasManyAssociationOperation.new(PlanetTypeResource, gas_giant.id, :planets, [betax.id, betay.id, betaz.id])
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    betax.reload
    betay.reload
    betaz.reload

    assert_equal(betax.planet_type_id, gas_giant.id)
    assert_equal(betay.planet_type_id, gas_giant.id)
    assert_equal(betaz.planet_type_id, gas_giant.id)

    #   Reset
    betax.planet_type_id = unknown.id
    betay.planet_type_id = unknown.id
    betaz.planet_type_id = unknown.id
    betax.save!
    betay.save!
    betaz.save!
  end

  def test_replace_attributes
    op = JSONAPI::OperationsProcessor.new()

    count = Planet.count
    saturn = Planet.find(1)
    assert_equal(saturn.name, 'Satern')

    operations = [
      JSONAPI::ReplaceFieldsOperation.new(PlanetResource, 1, {attributes: {'name' => 'saturn'}}),
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_kind_of(Array, results)
    assert_equal(results.size, 1)

    assert_kind_of(JSONAPI::OperationResult, results[0])
    assert_equal(:ok, results[0].code)

    saturn = Planet.find(1)

    assert_equal(saturn.name, 'saturn')

    assert_equal(Planet.count, count)
  end

  def test_remove_resource
    op = JSONAPI::OperationsProcessor.new

    count = Planet.count
    pluto = Planet.find(2)
    assert_equal(pluto.name, 'Pluto')

    operations = [
      JSONAPI::RemoveResourceOperation.new(PlanetResource, 2),
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_kind_of(Array, results)
    assert_equal(results.size, 1)

    assert_kind_of(JSONAPI::OperationResult, results[0])
    assert_equal(:no_content, results[0].code)
    assert_equal(Planet.count, count - 1)
  end

  def test_rollback_from_error
    op = JSONAPI::ActiveRecordOperationsProcessor.new

    count = Planet.count

    operations = [
      JSONAPI::RemoveResourceOperation.new(PlanetResource, 3),
      JSONAPI::RemoveResourceOperation.new(PlanetResource, 4),
      JSONAPI::RemoveResourceOperation.new(PlanetResource, 4)
    ]

    request = JSONAPI::Request.new
    request.operations = operations

    results = op.process(request)

    assert_equal(Planet.count, count)

    assert_kind_of(Array, results)
    assert_equal(results.size, 3)

    assert_kind_of(JSONAPI::OperationResult, results[0])
    assert_equal(:no_content, results[0].code)
    assert_equal(:no_content, results[1].code)
    assert_equal(404, results[2].code)
  end

end
