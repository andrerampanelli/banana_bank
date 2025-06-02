defmodule BananaBankWeb.UsersControllerTest do
  use BananaBankWeb.ConnCase, async: true

  alias BananaBank.Users.User
  alias BananaBank.Repo

  @valid_attrs %{
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    address: "123 Main St",
    balance: "100.00000"
  }

  @invalid_attrs %{
    name: nil,
    email: nil,
    password: nil,
    address: nil,
    balance: nil
  }

  @update_attrs %{
    name: "Jane Doe",
    email: "jane@example.com",
    address: "456 Oak Ave",
    balance: "200.00000"
  }

  describe "POST /api/users (create)" do
    test "creates user with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/users", @valid_attrs)

      assert %{
               "message" => "User created successfully",
               "data" => %{
                 "id" => id,
                 "name" => "John Doe",
                 "email" => "john@example.com",
                 "address" => "123 Main St",
                 "balance" => 100.0
               }
             } = json_response(conn, 201)

      assert is_integer(id)

      # Verify user was actually created in database
      user = Repo.get!(User, id)
      assert user.name == "John Doe"
      assert user.email == "john@example.com"
    end

    test "returns 422 with invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/users", @invalid_attrs)

      assert %{"errors" => errors} = json_response(conn, 422)
      assert is_map(errors)

      # Check that all required fields have errors
      assert Map.has_key?(errors, "name")
      assert Map.has_key?(errors, "email")
      assert Map.has_key?(errors, "password")
      assert Map.has_key?(errors, "address")
      assert Map.has_key?(errors, "balance")
    end

    test "returns 422 with invalid email format", %{conn: conn} do
      invalid_attrs = %{@valid_attrs | email: "invalid"}
      conn = post(conn, ~p"/api/users", invalid_attrs)

      assert %{"errors" => %{"email" => ["has invalid format"]}} = json_response(conn, 422)
    end

    test "returns 422 with invalid name format", %{conn: conn} do
      invalid_attrs = %{@valid_attrs | name: "Invalid123"}
      conn = post(conn, ~p"/api/users", invalid_attrs)

      assert %{"errors" => %{"name" => ["has invalid format"]}} = json_response(conn, 422)
    end

    test "handles balance formatting correctly", %{conn: conn} do
      attrs = %{@valid_attrs | balance: "123.45678"}
      conn = post(conn, ~p"/api/users", attrs)

      assert %{
               "data" => %{"balance" => 123.45}
             } = json_response(conn, 201)
    end

    test "excludes sensitive fields from response", %{conn: conn} do
      conn = post(conn, ~p"/api/users", @valid_attrs)

      response = json_response(conn, 201)
      data = response["data"]

      refute Map.has_key?(data, "password")
      refute Map.has_key?(data, "password_hash")
    end

    test "sets default balance when not provided", %{conn: conn} do
      attrs = Map.delete(@valid_attrs, :balance)
      conn = post(conn, ~p"/api/users", attrs)

      assert %{
               "data" => %{"balance" => 0.0}
             } = json_response(conn, 201)
    end

    test "validates field lengths", %{conn: conn} do
      # Name too long
      long_name = String.duplicate("a", 101)
      attrs = %{@valid_attrs | name: long_name}
      conn = post(conn, ~p"/api/users", attrs)

      assert %{"errors" => %{"name" => ["should be at most 100 character(s)"]}} =
               json_response(conn, 422)
    end

    test "handles unicode characters in name", %{conn: conn} do
      attrs = %{@valid_attrs | name: "José María García"}
      conn = post(conn, ~p"/api/users", attrs)

      assert %{
               "data" => %{"name" => "José María García"}
             } = json_response(conn, 201)
    end
  end

  describe "GET /api/users/:id (show)" do
    setup do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user: user}
    end

    test "returns user when found", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert %{
               "user" => %{
                 "id" => id,
                 "name" => "John Doe",
                 "email" => "john@example.com",
                 "address" => "123 Main St",
                 "balance" => 100.0
               }
             } = json_response(conn, 200)

      assert id == user.id
    end

    test "returns 404 when user not found", %{conn: conn} do
      conn = get(conn, ~p"/api/users/999999")

      assert %{"errors" => "Not found"} = json_response(conn, 404)
    end

    test "handles string id", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert %{"user" => user_data} = json_response(conn, 200)
      assert user_data["id"] == user.id
    end

    test "returns 404 for invalid id format", %{conn: conn} do
      conn = get(conn, ~p"/api/users/invalid")

      assert json_response(conn, 404)
    end

    test "excludes sensitive fields from response", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/users/#{user.id}")

      response = json_response(conn, 200)
      user_data = response["user"]

      refute Map.has_key?(user_data, "password")
      refute Map.has_key?(user_data, "password_hash")
    end

    test "handles balance formatting correctly", %{conn: conn} do
      # Create user with specific balance
      {:ok, user} =
        %{@valid_attrs | balance: "123.45678", email: "test@example.com"}
        |> User.changeset()
        |> Repo.insert()

      conn = get(conn, ~p"/api/users/#{user.id}")

      assert %{
               "user" => %{"balance" => 123.45}
             } = json_response(conn, 200)
    end
  end

  describe "PUT /api/users/:id (update)" do
    setup do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user: user}
    end

    test "updates user with valid data", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user.id}", @update_attrs)

      assert %{
               "message" => "User updated successfully",
               "user" => %{
                 "id" => id,
                 "name" => "Jane Doe",
                 "email" => "jane@example.com",
                 "address" => "456 Oak Ave",
                 "balance" => 200.0
               }
             } = json_response(conn, 200)

      assert id == user.id

      # Verify user was actually updated in database
      updated_user = Repo.get!(User, user.id)
      assert updated_user.name == "Jane Doe"
      assert updated_user.email == "jane@example.com"
    end

    test "returns 422 with invalid data", %{conn: conn, user: user} do
      invalid_attrs = %{@update_attrs | email: "invalid"}
      conn = put(conn, ~p"/api/users/#{user.id}", invalid_attrs)

      assert %{"errors" => %{"email" => ["has invalid format"]}} = json_response(conn, 422)

      # Verify user wasn't changed in database
      unchanged_user = Repo.get!(User, user.id)
      assert unchanged_user.email == user.email
    end

    test "returns 404 when user not found", %{conn: conn} do
      conn = put(conn, ~p"/api/users/999999", @update_attrs)

      assert %{"errors" => "Not found"} = json_response(conn, 404)
    end

    test "ignores password field in updates", %{conn: conn, user: user} do
      update_with_password = Map.put(@update_attrs, :password, "newpassword")
      conn = put(conn, ~p"/api/users/#{user.id}", update_with_password)

      assert json_response(conn, 200)

      # Verify password hash wasn't changed
      updated_user = Repo.get!(User, user.id)
      assert updated_user.password_hash == user.password_hash
    end

    test "handles partial updates", %{conn: conn, user: user} do
      partial_update = %{name: "Updated Name Only"}
      conn = put(conn, ~p"/api/users/#{user.id}", partial_update)

      assert %{
               "user" => %{
                 "name" => "Updated Name Only",
                 # unchanged
                 "email" => "john@example.com"
               }
             } = json_response(conn, 200)
    end

    test "validates updated fields", %{conn: conn, user: user} do
      # Test multiple invalid fields
      invalid_updates = [
        %{name: "Invalid123"},
        %{email: "invalid"},
        %{name: ""},
        %{address: ""}
      ]

      for invalid_update <- invalid_updates do
        conn = put(conn, ~p"/api/users/#{user.id}", invalid_update)
        assert json_response(conn, 422)
      end
    end

    test "handles balance formatting in updates", %{conn: conn, user: user} do
      update = %{balance: "123.45678"}
      conn = put(conn, ~p"/api/users/#{user.id}", update)

      assert %{
               "user" => %{"balance" => 123.45}
             } = json_response(conn, 200)
    end

    test "excludes sensitive fields from response", %{conn: conn, user: user} do
      conn = put(conn, ~p"/api/users/#{user.id}", @update_attrs)

      response = json_response(conn, 200)
      user_data = response["user"]

      refute Map.has_key?(user_data, "password")
      refute Map.has_key?(user_data, "password_hash")
    end
  end

  describe "DELETE /api/users/:id (delete)" do
    setup do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user: user}
    end

    test "deletes user successfully", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user.id}")

      assert %{
               "message" => "User deleted successfully"
             } = json_response(conn, 204)

      # Verify user was actually deleted from database
      assert Repo.get(User, user.id) == nil
    end

    test "returns 404 when user not found", %{conn: conn} do
      conn = delete(conn, ~p"/api/users/999999")

      assert %{"errors" => "Not found"} = json_response(conn, 404)
    end

    test "handles string id", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/api/users/#{user.id}")

      assert json_response(conn, 204)
      assert Repo.get(User, user.id) == nil
    end

    test "returns 404 for invalid id format", %{conn: conn} do
      conn = delete(conn, ~p"/api/users/invalid")

      assert json_response(conn, 404)
    end

    test "handles concurrent deletion", %{conn: conn, user: user} do
      # First deletion
      conn1 = delete(conn, ~p"/api/users/#{user.id}")
      assert json_response(conn1, 204)

      # Second deletion should return 404
      conn2 = delete(conn, ~p"/api/users/#{user.id}")
      assert json_response(conn2, 404)
    end
  end

  describe "error handling" do
    test "handles malformed JSON in create", %{conn: conn} do
      # This will throw an exception due to malformed JSON
      assert_raise Plug.Parsers.ParseError, fn ->
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/users", "{invalid json}")
      end
    end

    test "handles missing content-type header", %{conn: conn} do
      conn =
        conn
        |> delete_req_header("content-type")
        |> post(~p"/api/users", @valid_attrs)

      # Should still work as Phoenix handles this gracefully
      assert json_response(conn, 201)
    end

    test "handles empty request body in create", %{conn: conn} do
      conn = post(conn, ~p"/api/users", %{})

      assert %{"errors" => errors} = json_response(conn, 422)
      assert is_map(errors)
    end

    test "handles very large request bodies gracefully", %{conn: conn} do
      large_name = String.duplicate("a", 10000)
      attrs = %{@valid_attrs | name: large_name}

      conn = post(conn, ~p"/api/users", attrs)
      assert json_response(conn, 422)
    end
  end

  describe "content negotiation" do
    test "only accepts JSON content", %{conn: conn} do
      # The API pipeline only accepts JSON, so this should raise an error
      assert_raise Phoenix.NotAcceptableError, fn ->
        conn
        |> put_req_header("accept", "text/html")
        |> get(~p"/api/users/1")
      end
    end

    test "returns JSON content-type", %{conn: conn} do
      # Create a user for this test
      user = create_user()
      conn = get(conn, ~p"/api/users/#{user.id}")

      assert get_resp_header(conn, "content-type") |> hd() =~ "application/json"
    end
  end

  describe "integration flows" do
    test "full CRUD lifecycle", %{conn: conn} do
      # Create
      conn = post(conn, ~p"/api/users", @valid_attrs)
      assert %{"data" => %{"id" => user_id}} = json_response(conn, 201)

      # Show
      conn = get(conn, ~p"/api/users/#{user_id}")
      assert %{"user" => user_data} = json_response(conn, 200)
      assert user_data["id"] == user_id

      # Update
      conn = put(conn, ~p"/api/users/#{user_id}", @update_attrs)
      assert %{"user" => updated_data} = json_response(conn, 200)
      assert updated_data["name"] == "Jane Doe"

      # Verify update persisted
      conn = get(conn, ~p"/api/users/#{user_id}")
      assert %{"user" => %{"name" => "Jane Doe"}} = json_response(conn, 200)

      # Delete
      conn = delete(conn, ~p"/api/users/#{user_id}")
      assert json_response(conn, 204)

      # Verify deletion
      conn = get(conn, ~p"/api/users/#{user_id}")
      assert json_response(conn, 404)
    end

    test "balance consistency across operations", %{conn: conn} do
      # Create with specific balance
      attrs = %{@valid_attrs | balance: "123.45678"}
      conn = post(conn, ~p"/api/users", attrs)

      assert %{"data" => %{"id" => user_id, "balance" => 123.45}} =
               json_response(conn, 201)

      # Show should have same formatted balance
      conn = get(conn, ~p"/api/users/#{user_id}")
      assert %{"user" => %{"balance" => 123.45}} = json_response(conn, 200)

      # Update with different balance
      conn = put(conn, ~p"/api/users/#{user_id}", %{balance: "456.78912"})
      assert %{"user" => %{"balance" => 456.78}} = json_response(conn, 200)
    end
  end

  defp create_user(attrs \\ @valid_attrs) do
    attrs
    |> User.changeset()
    |> Repo.insert!()
  end
end
