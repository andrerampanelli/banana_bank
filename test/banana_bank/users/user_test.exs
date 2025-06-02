defmodule BananaBank.Users.UserTest do
  use BananaBank.DataCase, async: true

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

  describe "changeset/1 (create)" do
    test "valid changeset with all required fields" do
      changeset = User.changeset(@valid_attrs)

      assert changeset.valid?
      assert changeset.changes.name == "John Doe"
      assert changeset.changes.email == "john@example.com"
      assert changeset.changes.address == "123 Main St"
      assert changeset.changes.balance == "100.00000"
      assert changeset.changes.password_hash
    end

    test "invalid changeset with missing required fields" do
      changeset = User.changeset(@invalid_attrs)

      refute changeset.valid?

      assert %{
               name: ["can't be blank"],
               email: ["can't be blank"],
               password: ["can't be blank"],
               address: ["can't be blank"],
               balance: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "invalid changeset with invalid email format" do
      invalid_emails = [
        {"invalid", ["has invalid format"]},
        {"a@b", ["should be at least 5 character(s)", "has invalid format"]},
        {"test@a.b", ["has invalid format"]},
        {"@example.com", ["has invalid format"]},
        {"test@", ["has invalid format"]},
        {"test.com", ["has invalid format"]}
      ]

      for {email, expected_errors} <- invalid_emails do
        changeset = User.changeset(%{@valid_attrs | email: email})
        refute changeset.valid?
        assert %{email: ^expected_errors} = errors_on(changeset)
      end
    end

    test "valid changeset with valid email formats" do
      valid_emails = [
        "test@example.com",
        "user@domain.org",
        "name@test.co.uk"
      ]

      for email <- valid_emails do
        changeset = User.changeset(%{@valid_attrs | email: email})
        assert changeset.valid?
      end
    end

    test "invalid changeset with invalid name format" do
      invalid_names = [
        "John123",
        "John@Doe",
        "John_Doe",
        "123456",
        "Name!"
      ]

      for name <- invalid_names do
        changeset = User.changeset(%{@valid_attrs | name: name})
        refute changeset.valid?
        assert %{name: ["has invalid format"]} = errors_on(changeset)
      end
    end

    test "valid changeset with valid name formats" do
      valid_names = [
        "John Doe",
        "María García",
        "Jean-Claude",
        "O'Connor",
        "José António"
      ]

      for name <- valid_names do
        changeset = User.changeset(%{@valid_attrs | name: name})
        assert changeset.valid?
      end
    end

    test "invalid changeset with name too short or too long" do
      changeset_short = User.changeset(%{@valid_attrs | name: ""})
      refute changeset_short.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset_short)

      long_name = String.duplicate("a", 101)
      changeset_long = User.changeset(%{@valid_attrs | name: long_name})
      refute changeset_long.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset_long)
    end

    test "invalid changeset with email too short or too long" do
      # Email validation regex runs first, so short emails will fail regex validation
      changeset_short = User.changeset(%{@valid_attrs | email: "a@b.c"})
      refute changeset_short.valid?
      assert %{email: ["has invalid format"]} = errors_on(changeset_short)

      # 95 + 9 = 104 characters
      long_email = String.duplicate("a", 95) <> "@test.com"
      changeset_long = User.changeset(%{@valid_attrs | email: long_email})
      refute changeset_long.valid?
      assert %{email: ["should be at most 100 character(s)"]} = errors_on(changeset_long)
    end

    test "password is hashed when changeset is valid" do
      changeset = User.changeset(@valid_attrs)

      assert changeset.valid?
      assert changeset.changes.password_hash
      assert changeset.changes.password_hash != @valid_attrs.password
      assert Argon2.verify_pass(@valid_attrs.password, changeset.changes.password_hash)
    end

    test "password is not hashed when changeset is invalid" do
      changeset = User.changeset(%{@valid_attrs | email: "invalid"})

      refute changeset.valid?
      refute changeset.changes[:password_hash]
    end
  end

  describe "changeset/2 (update)" do
    setup do
      user = %User{
        id: 1,
        name: "Original Name",
        email: "original@example.com",
        address: "Original Address",
        balance: "50.00000",
        password_hash: "hashed_password"
      }

      {:ok, user: user}
    end

    test "valid update changeset without password", %{user: user} do
      update_attrs = %{
        name: "Updated Name",
        email: "updated@example.com",
        address: "Updated Address",
        balance: "75.00000"
      }

      changeset = User.changeset(user, update_attrs)

      assert changeset.valid?
      assert changeset.changes.name == "Updated Name"
      assert changeset.changes.email == "updated@example.com"
      assert changeset.changes.address == "Updated Address"
      assert Map.get(changeset.changes, :balance) == "75.00000"
      refute changeset.changes[:password_hash]
    end

    test "invalid update changeset with invalid fields", %{user: user} do
      update_attrs = %{
        name: "Invalid123",
        email: "invalid",
        address: ""
      }

      changeset = User.changeset(user, update_attrs)

      refute changeset.valid?

      assert %{
               name: ["has invalid format"],
               email: ["has invalid format"],
               address: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "password field should not be in update fields", %{user: user} do
      update_attrs = %{name: "Updated Name", password: "newpassword"}

      changeset = User.changeset(user, update_attrs)

      assert changeset.valid?
      refute changeset.changes[:password]
      refute changeset.changes[:password_hash]
    end
  end

  describe "Jason.Encoder implementation" do
    setup do
      user = %User{
        id: 1,
        name: "John Doe",
        email: "john@example.com",
        address: "123 Main St",
        balance: "123.45678",
        password_hash: "secret_hash"
      }

      {:ok, user: user}
    end

    test "encodes user with correct fields", %{user: user} do
      encoded = Jason.encode!(user)
      decoded = Jason.decode!(encoded)

      assert decoded["id"] == 1
      assert decoded["name"] == "John Doe"
      assert decoded["email"] == "john@example.com"
      assert decoded["address"] == "123 Main St"
      assert decoded["balance"] == 123.45
      refute Map.has_key?(decoded, "password")
      refute Map.has_key?(decoded, "password_hash")
    end

    test "handles balance rounding correctly" do
      test_cases = [
        {"123.456", 123.45},
        {"123.454", 123.45},
        {"100.00000", 100.0},
        {"0.00000", 0.0},
        {"999.999", 999.99}
      ]

      for {balance_string, expected} <- test_cases do
        user = %User{
          id: 1,
          name: "Test",
          email: "test@example.com",
          address: "Test Address",
          balance: balance_string
        }

        encoded = Jason.encode!(user)
        decoded = Jason.decode!(encoded)
        assert decoded["balance"] == expected
      end
    end

    test "handles invalid balance string" do
      user = %User{
        id: 1,
        name: "Test",
        email: "test@example.com",
        address: "Test Address",
        balance: "invalid"
      }

      encoded = Jason.encode!(user)
      decoded = Jason.decode!(encoded)
      assert decoded["balance"] == 0.0
    end

    test "handles empty balance string" do
      user = %User{
        id: 1,
        name: "Test",
        email: "test@example.com",
        address: "Test Address",
        balance: ""
      }

      encoded = Jason.encode!(user)
      decoded = Jason.decode!(encoded)
      assert decoded["balance"] == 0.0
    end

    test "handles nil balance" do
      user = %User{
        id: 1,
        name: "Test",
        email: "test@example.com",
        address: "Test Address",
        balance: nil
      }

      encoded = Jason.encode!(user)
      decoded = Jason.decode!(encoded)
      assert decoded["balance"] == 0.0
    end
  end
end
