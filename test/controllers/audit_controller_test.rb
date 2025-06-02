require "test_helper"

class AuditControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get audit_new_url
    assert_response :success
  end

  test "should get create" do
    get audit_create_url
    assert_response :success
  end
end
