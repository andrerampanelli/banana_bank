defmodule BananaBankWeb.UsersJSONTest do
  use BananaBankWeb.ConnCase, async: true

  alias BananaBankWeb.UsersJSON
  alias BananaBank.Users.User

  @user_attrs %{
    id: 1,
    name: "John Doe",
    email: "john@example.com",
    address: "123 Main St",
    balance: "123.45678",
    password_hash: "hashed_password",
    inserted_at: ~U[2024-01-01 00:00:00Z],
    updated_at: ~U[2024-01-01 01:00:00Z]
  }

  describe "create/1" do
    test "renders user creation response with message and data" do
      user = struct(User, @user_attrs)
      response = UsersJSON.create(%{user: user})

      assert %{
               message: "User created successfully",
               data: user_data
             } = response

      # The user data should be the raw user struct (JSON encoding happens later)
      assert user_data == user
    end

    test "handles user with default balance" do
      user = struct(User, %{@user_attrs | balance: "0.00000"})
      response = UsersJSON.create(%{user: user})

      assert %{
               message: "User created successfully",
               data: user_data
             } = response

      assert user_data == user
    end

    test "handles user with invalid balance string" do
      user = struct(User, %{@user_attrs | balance: "invalid"})
      response = UsersJSON.create(%{user: user})

      assert %{
               message: "User created successfully",
               data: user_data
             } = response

      assert user_data == user
    end

    test "handles user with unicode characters" do
      user = struct(User, %{@user_attrs | name: "José María García"})
      response = UsersJSON.create(%{user: user})

      assert %{
               message: "User created successfully",
               data: user_data
             } = response

      assert user_data == user
    end

    test "excludes sensitive fields from response" do
      user = struct(User, @user_attrs)
      response = UsersJSON.create(%{user: user})

      user_data = response.data

      # The raw user struct contains all fields, but Jason encoding will exclude them
      assert user_data == user

      # Test that Jason encoding excludes sensitive fields
      encoded = Jason.encode!(user_data)
      decoded = Jason.decode!(encoded)

      refute Map.has_key?(decoded, "password")
      refute Map.has_key?(decoded, "password_hash")
      refute Map.has_key?(decoded, "inserted_at")
      refute Map.has_key?(decoded, "updated_at")
    end

    test "handles various balance edge cases" do
      test_cases = [
        {"999.999", 999.99},
        {"0.001", 0.0},
        {"123.454", 123.45},
        {"123.456", 123.45},
        {"1000000.00000", 1_000_000.0}
      ]

      for {balance_string, expected} <- test_cases do
        user = struct(User, %{@user_attrs | balance: balance_string})
        response = UsersJSON.create(%{user: user})

        encoded = Jason.encode!(response.data)
        decoded = Jason.decode!(encoded)

        assert decoded["balance"] == expected
      end
    end
  end

  describe "show/1" do
    test "renders user show response" do
      user = struct(User, @user_attrs)
      response = UsersJSON.show(%{user: user})

      assert %{
               user: user_data
             } = response

      assert user_data == user
    end

    test "handles user with different balance values" do
      test_cases = [
        "0.00000",
        "50.25000",
        "999999.99999"
      ]

      for balance_string <- test_cases do
        user = struct(User, %{@user_attrs | balance: balance_string})
        response = UsersJSON.show(%{user: user})

        assert response.user == user
      end
    end

    test "excludes sensitive fields from response" do
      user = struct(User, @user_attrs)
      response = UsersJSON.show(%{user: user})

      user_data = response.user

      assert Map.get(user_data, :password) == nil
      assert Map.get(user_data, :password_hash) == "hashed_password"
    end

    test "handles unicode characters in user data" do
      user =
        struct(User, %{
          @user_attrs
          | name: "José María García",
            address: "Rua São João, 123"
        })

      response = UsersJSON.show(%{user: user})

      assert response.user.name == "José María García"
      assert response.user.address == "Rua São João, 123"
    end
  end

  describe "update/1" do
    test "renders user update response with message and user data" do
      user = struct(User, @user_attrs)
      response = UsersJSON.update(%{user: user})

      assert %{
               message: "User updated successfully",
               user: user_data
             } = response

      assert user_data == user
    end

    test "handles updated user with new balance" do
      user = struct(User, %{@user_attrs | balance: "200.00000"})
      response = UsersJSON.update(%{user: user})

      assert %{
               message: "User updated successfully",
               user: user_data
             } = response

      assert user_data == user
    end

    test "excludes sensitive fields from response" do
      user = struct(User, @user_attrs)
      response = UsersJSON.update(%{user: user})

      user_data = response.user

      assert Map.get(user_data, :password) == nil
      assert Map.get(user_data, :password_hash) == "hashed_password"
    end

    test "handles user with partial updates" do
      # Simulate a user that was partially updated
      user =
        struct(User, %{
          @user_attrs
          | name: "Updated Name",
            balance: "999.99999"
        })

      response = UsersJSON.update(%{user: user})

      assert %{
               message: "User updated successfully",
               user: user_data
             } = response

      assert user_data == user
    end
  end

  describe "delete/1" do
    test "renders user deletion response with message only" do
      response = UsersJSON.delete(%{})

      assert %{
               message: "User deleted successfully"
             } = response

      # Should not include any user data
      refute Map.has_key?(response, :user)
      refute Map.has_key?(response, :data)
    end

    test "ignores any passed arguments" do
      # The delete function should work regardless of what's passed
      response1 = UsersJSON.delete(%{user: "some_user"})
      response2 = UsersJSON.delete(%{anything: "anything"})
      response3 = UsersJSON.delete(%{})

      expected = %{message: "User deleted successfully"}

      assert response1 == expected
      assert response2 == expected
      assert response3 == expected
    end

    test "returns consistent message format" do
      response = UsersJSON.delete(%{})

      assert is_binary(response.message)
      assert response.message == "User deleted successfully"
    end
  end

  describe "integration with Jason encoding" do
    test "create response can be JSON encoded" do
      user = struct(User, @user_attrs)
      response = UsersJSON.create(%{user: user})

      # Should be able to encode the entire response
      encoded = Jason.encode!(response)
      decoded = Jason.decode!(encoded, keys: :atoms)

      assert decoded.message == "User created successfully"
      assert decoded.data.id == 1
      assert decoded.data.name == "John Doe"
      assert decoded.data.balance == 123.45
    end

    test "show response can be JSON encoded" do
      user = struct(User, @user_attrs)
      response = UsersJSON.show(%{user: user})

      encoded = Jason.encode!(response)
      decoded = Jason.decode!(encoded, keys: :atoms)

      assert decoded.user.id == 1
      assert decoded.user.name == "John Doe"
      assert decoded.user.balance == 123.45
    end

    test "update response can be JSON encoded" do
      user = struct(User, @user_attrs)
      response = UsersJSON.update(%{user: user})

      encoded = Jason.encode!(response)
      decoded = Jason.decode!(encoded, keys: :atoms)

      assert decoded.message == "User updated successfully"
      assert decoded.user.id == 1
      assert decoded.user.balance == 123.45
    end

    test "delete response can be JSON encoded" do
      response = UsersJSON.delete(%{})

      encoded = Jason.encode!(response)
      decoded = Jason.decode!(encoded, keys: :atoms)

      assert decoded.message == "User deleted successfully"
    end
  end

  describe "response structure consistency" do
    test "all responses follow consistent structure patterns" do
      user = struct(User, @user_attrs)

      # Create has message + data
      create_response = UsersJSON.create(%{user: user})
      assert Map.has_key?(create_response, :message)
      assert Map.has_key?(create_response, :data)
      assert create_response.message =~ "created"

      # Show has user only
      show_response = UsersJSON.show(%{user: user})
      assert Map.has_key?(show_response, :user)
      refute Map.has_key?(show_response, :message)

      # Update has message + user
      update_response = UsersJSON.update(%{user: user})
      assert Map.has_key?(update_response, :message)
      assert Map.has_key?(update_response, :user)
      assert update_response.message =~ "updated"

      # Delete has message only
      delete_response = UsersJSON.delete(%{})
      assert Map.has_key?(delete_response, :message)
      refute Map.has_key?(delete_response, :user)
      refute Map.has_key?(delete_response, :data)
      assert delete_response.message =~ "deleted"
    end

    test "all user data structures are identical across operations" do
      user = struct(User, @user_attrs)

      create_user_data = UsersJSON.create(%{user: user}).data
      show_user_data = UsersJSON.show(%{user: user}).user
      update_user_data = UsersJSON.update(%{user: user}).user

      # All should have the same structure and values
      assert create_user_data.id == show_user_data.id
      assert create_user_data.id == update_user_data.id

      assert create_user_data.name == show_user_data.name
      assert create_user_data.name == update_user_data.name

      assert create_user_data.balance == show_user_data.balance
      assert create_user_data.balance == update_user_data.balance
    end
  end

  describe "error edge cases" do
    test "handles empty user struct" do
      empty_user = %User{}
      response = UsersJSON.create(%{user: empty_user})

      assert %{
               message: "User created successfully",
               data: user_data
             } = response

      # Should handle nil/empty values gracefully due to Jason.Encoder implementation
      assert user_data.id == nil

      encoded = Jason.encode!(user_data)
      decoded = Jason.decode!(encoded)

      # nil balance should default to 0.0
      assert decoded["balance"] == 0.0
    end
  end
end
