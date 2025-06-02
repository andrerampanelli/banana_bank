defmodule BananaBank.Users.UpdateTest do
  use BananaBank.DataCase, async: true

  alias BananaBank.Users.Update
  alias BananaBank.Users.User

  @valid_attrs %{
    name: "John Doe",
    email: "john@example.com",
    password: "password123",
    address: "123 Main St",
    balance: "100.00000"
  }

  @update_attrs %{
    name: "Jane Doe",
    email: "jane@example.com",
    address: "456 Oak Ave",
    balance: "200.00000"
  }

  describe "call/2" do
    setup do
      {:ok, user} =
        @valid_attrs
        |> User.changeset()
        |> Repo.insert()

      {:ok, user: user}
    end

    test "successfully updates user with valid data", %{user: user} do
      assert {:ok, %User{} = updated_user} = Update.call(user.id, @update_attrs)

      assert updated_user.id == user.id
      assert updated_user.name == "Jane Doe"
      assert updated_user.email == "jane@example.com"
      assert updated_user.address == "456 Oak Ave"
      assert updated_user.balance == "200.00000"

      # Password hash should remain unchanged
      assert updated_user.password_hash == user.password_hash
    end

    test "returns {:error, :not_found} when user does not exist" do
      non_existent_id = 999_999
      assert {:error, :not_found} = Update.call(non_existent_id, @update_attrs)
    end

    test "returns error changeset with invalid data", %{user: user} do
      invalid_attrs = %{@update_attrs | email: "invalid"}
      assert {:error, %Ecto.Changeset{} = changeset} = Update.call(user.id, invalid_attrs)
      assert %{email: ["has invalid format"]} = errors_on(changeset)

      # Verify user wasn't changed in database
      unchanged_user = Repo.get!(User, user.id)
      assert unchanged_user.email == user.email
    end

    test "handles string id that can be converted to integer", %{user: user} do
      string_id = Integer.to_string(user.id)
      assert {:ok, %User{} = updated_user} = Update.call(string_id, @update_attrs)
      assert updated_user.id == user.id
      assert updated_user.name == "Jane Doe"
    end

    test "returns {:error, :not_found} for string id that doesn't exist" do
      assert {:error, :not_found} = Update.call("999999", @update_attrs)
    end

    test "returns {:error, :not_found} for invalid string id" do
      assert {:error, :not_found} = Update.call("invalid", @update_attrs)
    end

    test "returns {:error, :not_found} for nil id" do
      assert {:error, :not_found} = Update.call(nil, @update_attrs)
    end

    test "ignores password field in updates", %{user: user} do
      update_with_password = Map.put(@update_attrs, :password, "newpassword")
      assert {:ok, %User{} = updated_user} = Update.call(user.id, update_with_password)

      # Password hash should remain unchanged
      assert updated_user.password_hash == user.password_hash
      # Verify password still works with original password
      assert Argon2.verify_pass(@valid_attrs.password, updated_user.password_hash)
    end

    test "ignores password_hash field in updates", %{user: user} do
      malicious_update = Map.put(@update_attrs, :password_hash, "malicious_hash")
      assert {:ok, %User{} = updated_user} = Update.call(user.id, malicious_update)

      # Password hash should remain unchanged
      assert updated_user.password_hash == user.password_hash
    end

    test "updates only allowed fields", %{user: user} do
      # Try to update timestamps (should be ignored)
      malicious_update =
        Map.merge(@update_attrs, %{
          inserted_at: ~U[2020-01-01 00:00:00Z],
          updated_at: ~U[2020-01-01 00:00:00Z]
        })

      assert {:ok, %User{} = updated_user} = Update.call(user.id, malicious_update)

      # Timestamps should not be the malicious values
      refute updated_user.inserted_at == ~U[2020-01-01 00:00:00Z]
      refute updated_user.updated_at == ~U[2020-01-01 00:00:00Z]
    end

    test "validates all update fields", %{user: user} do
      # Test invalid name
      assert {:error, changeset} = Update.call(user.id, %{name: "Invalid123"})
      assert %{name: ["has invalid format"]} = errors_on(changeset)

      # Test invalid email
      assert {:error, changeset} = Update.call(user.id, %{email: "invalid"})
      assert %{email: ["has invalid format"]} = errors_on(changeset)

      # Test empty required fields
      assert {:error, changeset} = Update.call(user.id, %{name: ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)

      assert {:error, changeset} = Update.call(user.id, %{address: ""})
      assert %{address: ["can't be blank"]} = errors_on(changeset)

      # Balance is optional for updates, so empty string should be allowed
      assert {:ok, _} = Update.call(user.id, %{balance: ""})
    end

    test "validates field lengths in updates", %{user: user} do
      # Name too long
      long_name = String.duplicate("a", 101)
      assert {:error, changeset} = Update.call(user.id, %{name: long_name})
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)

      # Email too short
      assert {:error, changeset} = Update.call(user.id, %{email: "a@b.c"})
      assert %{email: ["has invalid format"]} = errors_on(changeset)

      # Email too long
      long_email = String.duplicate("a", 100) <> "@test.com"
      assert {:error, changeset} = Update.call(user.id, %{email: long_email})
      assert %{email: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "handles partial updates", %{user: user} do
      # Update only name
      partial_update = %{name: "Updated Name Only"}
      assert {:ok, %User{} = updated_user} = Update.call(user.id, partial_update)

      assert updated_user.name == "Updated Name Only"
      # unchanged
      assert updated_user.email == user.email
      # unchanged
      assert updated_user.address == user.address
      # unchanged
      assert updated_user.balance == user.balance
    end

    test "handles unicode characters in updates", %{user: user} do
      unicode_update = %{name: "José María García"}
      assert {:ok, %User{} = updated_user} = Update.call(user.id, unicode_update)
      assert updated_user.name == "José María García"
    end

    test "handles various balance formats in updates", %{user: user} do
      balance_updates = [
        "0.00000",
        "999999.99999",
        "1.23456"
      ]

      for balance <- balance_updates do
        assert {:ok, %User{} = updated_user} = Update.call(user.id, %{balance: balance})
        assert updated_user.balance == balance
      end
    end

    test "persists updates to database", %{user: user} do
      assert {:ok, %User{} = updated_user} = Update.call(user.id, @update_attrs)

      # Verify changes are persisted
      db_user = Repo.get!(User, user.id)
      assert db_user.name == updated_user.name
      assert db_user.email == updated_user.email
      assert db_user.address == updated_user.address
      assert db_user.balance == updated_user.balance
    end

    test "handles concurrent updates gracefully", %{user: user} do
      # This is a basic test - in a real system you might test optimistic locking
      # For now, we just verify multiple updates work

      assert {:ok, _} = Update.call(user.id, %{name: "First Update"})
      assert {:ok, updated_user} = Update.call(user.id, %{name: "Second Update"})

      assert updated_user.name == "Second Update"
    end

    test "handles empty update attrs", %{user: user} do
      assert {:ok, %User{} = updated_user} = Update.call(user.id, %{})

      # All fields should remain the same
      assert updated_user.name == user.name
      assert updated_user.email == user.email
      assert updated_user.address == user.address
      assert updated_user.balance == user.balance
    end
  end

  describe "error scenarios" do
    test "handles various invalid id types" do
      invalid_ids = [
        :atom,
        %{},
        [],
        {:tuple},
        self(),
        -1,
        0,
        1.5
      ]

      for invalid_id <- invalid_ids do
        assert {:error, :not_found} = Update.call(invalid_id, @update_attrs)
      end
    end
  end
end
