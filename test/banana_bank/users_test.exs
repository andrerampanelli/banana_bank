defmodule BananaBank.UsersTest do
  use BananaBank.DataCase, async: true

  alias BananaBank.Users
  alias BananaBank.Users.User

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

  describe "create/1" do
    test "creates user with valid data" do
      assert {:ok, %User{} = user} = Users.create(@valid_attrs)
      assert user.name == "John Doe"
      assert user.email == "john@example.com"
      assert user.address == "123 Main St"
      assert user.balance == "100.00000"
      assert user.password_hash
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Users.create(@invalid_attrs)
    end

    test "returns error changeset with invalid email format" do
      invalid_attrs = %{@valid_attrs | email: "invalid"}
      assert {:error, %Ecto.Changeset{} = changeset} = Users.create(invalid_attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)
    end

    test "returns error changeset with invalid name format" do
      invalid_attrs = %{@valid_attrs | name: "Invalid123"}
      assert {:error, %Ecto.Changeset{} = changeset} = Users.create(invalid_attrs)
      assert %{name: ["has invalid format"]} = errors_on(changeset)
    end

    test "hashes password correctly" do
      assert {:ok, %User{} = user} = Users.create(@valid_attrs)
      assert Argon2.verify_pass(@valid_attrs.password, user.password_hash)
    end
  end

  describe "get/1" do
    setup do
      {:ok, user} = Users.create(@valid_attrs)
      {:ok, user: user}
    end

    test "returns user when found", %{user: user} do
      assert {:ok, returned_user} = Users.get(user.id)
      assert returned_user.id == user.id
      assert returned_user.name == user.name
      assert returned_user.email == user.email
    end

    test "returns error when user not found" do
      assert {:error, :not_found} = Users.get(999)
    end

    test "returns error when user not found with string id" do
      assert {:error, :not_found} = Users.get("999")
    end

    test "returns error with invalid id format" do
      assert {:error, :not_found} = Users.get("invalid")
    end

    test "returns error with nil id" do
      assert {:error, :not_found} = Users.get(nil)
    end
  end

  describe "update/2" do
    setup do
      {:ok, user} = Users.create(@valid_attrs)
      {:ok, user: user}
    end

    test "updates user with valid data", %{user: user} do
      assert {:ok, %User{} = updated_user} = Users.update(user.id, @update_attrs)
      assert updated_user.name == "Jane Doe"
      assert updated_user.email == "jane@example.com"
      assert updated_user.address == "456 Oak Ave"
      assert updated_user.balance == "200.00000"
      assert updated_user.id == user.id
    end

    test "returns error changeset with invalid data", %{user: user} do
      invalid_update = %{@update_attrs | email: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Users.update(user.id, invalid_update)

      # Verify user wasn't changed
      assert {:ok, unchanged_user} = Users.get(user.id)
      assert unchanged_user.email == user.email
    end

    test "returns error when user not found" do
      assert {:error, :not_found} = Users.update(999, @update_attrs)
    end

    test "returns error with string id for non-existing user" do
      assert {:error, :not_found} = Users.update("999", @update_attrs)
    end

    test "returns error with invalid id format" do
      assert {:error, :not_found} = Users.update("invalid", @update_attrs)
    end

    test "ignores password field in updates", %{user: user} do
      update_with_password = Map.put(@update_attrs, :password, "newpassword")
      assert {:ok, %User{} = updated_user} = Users.update(user.id, update_with_password)

      # Password hash should remain the same
      assert updated_user.password_hash == user.password_hash
    end

    test "updates only allowed fields", %{user: user} do
      # Try to update a field that shouldn't be updatable
      malicious_update = Map.put(@update_attrs, :password_hash, "malicious_hash")
      assert {:ok, %User{} = updated_user} = Users.update(user.id, malicious_update)

      # Password hash should remain the same
      assert updated_user.password_hash == user.password_hash
    end

    test "validates updated fields", %{user: user} do
      invalid_updates = [
        %{name: "Invalid123"},
        %{email: "invalid"},
        %{name: ""},
        %{address: ""}
      ]

      for invalid_update <- invalid_updates do
        assert {:error, %Ecto.Changeset{}} = Users.update(user.id, invalid_update)
      end
    end
  end

  describe "delete/1" do
    setup do
      {:ok, user} = Users.create(@valid_attrs)
      {:ok, user: user}
    end

    test "deletes user successfully", %{user: user} do
      assert {:ok, %User{}} = Users.delete(user.id)
      assert {:error, :not_found} = Users.get(user.id)
    end

    test "returns error when user not found" do
      assert {:error, :not_found} = Users.delete(999)
    end

    test "returns error with string id for non-existing user" do
      assert {:error, :not_found} = Users.delete("999")
    end

    test "returns error with invalid id format" do
      assert {:error, :not_found} = Users.delete("invalid")
    end

    test "returns error with nil id" do
      assert {:error, :not_found} = Users.delete(nil)
    end

    test "returns deleted user data", %{user: user} do
      assert {:ok, %User{} = deleted_user} = Users.delete(user.id)
      assert deleted_user.id == user.id
      assert deleted_user.name == user.name
      assert deleted_user.email == user.email
    end
  end

  describe "integration scenarios" do
    test "create, get, update, delete flow" do
      # Create
      assert {:ok, %User{} = user} = Users.create(@valid_attrs)
      user_id = user.id

      # Get
      assert {:ok, fetched_user} = Users.get(user_id)
      assert fetched_user.id == user_id

      # Update
      assert {:ok, updated_user} = Users.update(user_id, @update_attrs)
      assert updated_user.name == "Jane Doe"

      # Get updated
      assert {:ok, fetched_updated} = Users.get(user_id)
      assert fetched_updated.name == "Jane Doe"

      # Delete
      assert {:ok, _deleted_user} = Users.delete(user_id)

      # Verify deleted
      assert {:error, :not_found} = Users.get(user_id)
    end

    test "multiple users can exist with different emails" do
      user1_attrs = @valid_attrs
      user2_attrs = %{@valid_attrs | email: "user2@example.com"}

      assert {:ok, user1} = Users.create(user1_attrs)
      assert {:ok, user2} = Users.create(user2_attrs)

      assert user1.id != user2.id
      assert user1.email != user2.email

      assert {:ok, _} = Users.get(user1.id)
      assert {:ok, _} = Users.get(user2.id)
    end
  end

  describe "edge cases" do
    test "handles empty string fields correctly" do
      attrs_with_empty = %{
        name: "",
        email: "",
        password: "",
        address: "",
        balance: ""
      }

      assert {:error, changeset} = Users.create(attrs_with_empty)

      assert %{
               name: ["can't be blank"],
               email: ["can't be blank"],
               password: ["can't be blank"],
               address: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "handles unicode characters in name" do
      unicode_attrs = %{@valid_attrs | name: "José María García"}
      assert {:ok, %User{} = user} = Users.create(unicode_attrs)
      assert user.name == "José María García"
    end

    test "handles very large balance numbers" do
      large_balance_attrs = %{@valid_attrs | balance: "999999999.99999"}
      assert {:ok, %User{} = user} = Users.create(large_balance_attrs)
      assert user.balance == "999999999.99999"
    end

    test "handles zero balance" do
      zero_balance_attrs = %{@valid_attrs | balance: "0.00000"}
      assert {:ok, %User{} = user} = Users.create(zero_balance_attrs)
      assert user.balance == "0.00000"
    end
  end
end
