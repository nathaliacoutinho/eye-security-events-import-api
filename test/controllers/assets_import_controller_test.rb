require "test_helper"

class AssetsImportControllerTest < ActionDispatch::IntegrationTest
  test "should get import" do
    get assets_import_import_url
    assert_response :success
  end
end
