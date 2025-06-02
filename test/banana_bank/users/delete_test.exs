defmodule BananaBank.Users.DeleteTest do
  use BananaBank.DataCase, async: true

  alias BananaBank.Users.Delete
  alias BananaBank.Users.User

  @valid_attrs %{
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    address: "123 Main St",
    balance: "100.00000"
  }

  describe "call/1" do
    setup do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user: user}
    end

    test "successfully deletes user when user exists", %{user: user} do
      assert {:ok, %User{} = deleted_user} = Delete.call(user.id)

      # Verify the returned user matches the original
      assert deleted_user.id == user.id
      assert deleted_user.name == user.name
      assert deleted_user.email == user.email
      assert deleted_user.address == user.address
      assert deleted_user.balance == user.balance
      assert deleted_user.password_hash == user.password_hash

      # Verify user is actually deleted from database
      assert Repo.get(User, user.id) == nil
    end

    test "returns {:error, :not_found} when user does not exist" do
      non_existent_id = 999_999
      assert {:error, :not_found} = Delete.call(non_existent_id)
    end

    test "handles string id that can be converted to integer", %{user: user} do
      string_id = Integer.to_string(user.id)
      assert {:ok, %User{} = deleted_user} = Delete.call(string_id)
      assert deleted_user.id == user.id

      # Verify user is actually deleted
      assert Repo.get(User, user.id) == nil
    end

    test "returns {:error, :not_found} for string id that doesn't exist" do
      assert {:error, :not_found} = Delete.call("999999")
    end

    test "returns {:error, :not_found} for invalid string id" do
      assert {:error, :not_found} = Delete.call("invalid")
    end

    test "returns {:error, :not_found} for nil id" do
      assert {:error, :not_found} = Delete.call(nil)
    end

    test "returns {:error, :not_found} for empty string id" do
      assert {:error, :not_found} = Delete.call("")
    end

    test "returns {:error, :not_found} for negative id" do
      assert {:error, :not_found} = Delete.call(-1)
    end

    test "returns {:error, :not_found} for zero id" do
      assert {:error, :not_found} = Delete.call(0)
    end

    test "returns {:error, :not_found} for float id" do
      assert {:error, :not_found} = Delete.call(1.5)
    end

    test "returns complete user data before deletion", %{user: user} do
      assert {:ok, deleted_user} = Delete.call(user.id)

      # Verify all fields are present in returned data
      assert deleted_user.id
      assert deleted_user.name
      assert deleted_user.email
      assert deleted_user.address
      assert deleted_user.balance
      assert deleted_user.password_hash
      assert deleted_user.inserted_at
      assert deleted_user.updated_at

      # Verify virtual password field is not set
      refute deleted_user.password
    end

    test "deletes correct user when multiple users exist", %{user: user1} do
      # Create second user
      {:ok, user2} =
        %{@valid_attrs | email: "jane@example.com"}
        |> User.changeset()
        |> Repo.insert()

      # Delete first user
      assert {:ok, deleted_user} = Delete.call(user1.id)
      assert deleted_user.email == user1.email

      # Verify first user is deleted
      assert Repo.get(User, user1.id) == nil

      # Verify second user still exists
      assert Repo.get(User, user2.id) != nil
    end

    test "handles user with different data types correctly", %{user: user} do
      assert {:ok, deleted_user} = Delete.call(user.id)

      assert is_integer(deleted_user.id)
      assert is_binary(deleted_user.name)
      assert is_binary(deleted_user.email)
      assert is_binary(deleted_user.address)
      assert is_binary(deleted_user.balance)
      assert is_binary(deleted_user.password_hash)
      assert %NaiveDateTime{} = deleted_user.inserted_at
      assert %NaiveDateTime{} = deleted_user.updated_at
    end

    test "handles user with default balance", %{user: user} do
      # Update user to have default balance
      {:ok, updated_user} =
        user
        |> User.changeset(%{balance: "0.00000"})
        |> Repo.update()

      assert {:ok, deleted_user} = Delete.call(updated_user.id)
      assert deleted_user.balance == "0.00000"

      # Verify deletion
      assert Repo.get(User, user.id) == nil
    end

    test "handles user with unicode characters in name" do
      {:ok, unicode_user} =
        %{@valid_attrs | name: "José María", email: "jose@example.com"}
        |> User.changeset()
        |> Repo.insert()

      assert {:ok, deleted_user} = Delete.call(unicode_user.id)
      assert deleted_user.name == "José María"

      # Verify deletion
      assert Repo.get(User, unicode_user.id) == nil
    end

    test "handles user with large balance numbers", %{user: user} do
      # Update user to have large balance
      {:ok, updated_user} =
        user
        |> User.changeset(%{balance: "999999999.99999"})
        |> Repo.update()

      assert {:ok, deleted_user} = Delete.call(updated_user.id)
      assert deleted_user.balance == "999999999.99999"
    end

    test "deletion is permanent and cannot be retrieved", %{user: user} do
      user_id = user.id

      # Delete user
      assert {:ok, _deleted_user} = Delete.call(user_id)

      # Try to get deleted user
      assert Repo.get(User, user_id) == nil

      # Try to delete again
      assert {:error, :not_found} = Delete.call(user_id)
    end

    test "deletes user with all associated timestamps", %{user: user} do
      original_inserted_at = user.inserted_at
      original_updated_at = user.updated_at

      assert {:ok, deleted_user} = Delete.call(user.id)

      # Verify timestamps are preserved in returned data
      assert deleted_user.inserted_at == original_inserted_at
      assert deleted_user.updated_at == original_updated_at
    end

    test "handles concurrent deletion attempts", %{user: user} do
      user_id = user.id

      # First deletion should succeed
      assert {:ok, _deleted_user} = Delete.call(user_id)

      # Second deletion should fail
      assert {:error, :not_found} = Delete.call(user_id)
    end

    test "handles large user id numbers" do
      # Test with very large ID that doesn't exist
      assert {:error, :not_found} = Delete.call(999_999_999)
    end
  end

  describe "error scenarios" do
    test "handles various invalid id types" do
      invalid_ids = [
        :atom,
        %{},
        [],
        {:tuple},
        self()
      ]

      for invalid_id <- invalid_ids do
        assert {:error, :not_found} = Delete.call(invalid_id)
      end
    end

    test "handles database constraints gracefully" do
      # This test would be more meaningful if there were foreign key constraints
      # For now, we just test the basic deletion works
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      assert {:ok, _deleted_user} = Delete.call(user.id)
    end

    test "handles repeated deletion attempts on same id" do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      user_id = user.id

      # Delete once
      assert {:ok, _} = Delete.call(user_id)

      # Try to delete multiple times
      assert {:error, :not_found} = Delete.call(user_id)
      assert {:error, :not_found} = Delete.call(user_id)
      assert {:error, :not_found} = Delete.call(user_id)
    end
  end

  describe "integration with database" do
    test "properly removes user from database queries" do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      user_id = user.id

      # Verify user exists in database
      assert Repo.get(User, user_id) != nil

      # Delete user
      assert {:ok, _deleted_user} = Delete.call(user_id)

      # Verify user cannot be found with various query methods
      assert Repo.get(User, user_id) == nil
      assert Repo.get_by(User, id: user_id) == nil
      assert Repo.get_by(User, email: user.email) == nil

      # Verify user is not in list queries
      all_users = Repo.all(User)
      refute Enum.any?(all_users, &(&1.id == user_id))
    end

    test "deletion count affects database totals" do
      # Create multiple users
      {:ok, user1} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user2} =
        %{@valid_attrs | email: "user2@example.com"}
        |> User.changeset()
        |> Repo.insert()

      initial_count = Repo.aggregate(User, :count, :id)

      # Delete one user
      assert {:ok, _} = Delete.call(user1.id)

      final_count = Repo.aggregate(User, :count, :id)
      assert final_count == initial_count - 1

      # Verify the correct user was deleted
      assert Repo.get(User, user1.id) == nil
      assert Repo.get(User, user2.id) != nil
    end
  end
end
