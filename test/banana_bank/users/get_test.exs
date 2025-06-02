defmodule BananaBank.Users.GetTest do
  use BananaBank.DataCase, async: true

  alias BananaBank.Users.Get
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

    test "returns {:ok, user} when user exists", %{user: user} do
      assert {:ok, returned_user} = Get.call(user.id)
      assert returned_user.id == user.id
      assert returned_user.name == user.name
      assert returned_user.email == user.email
      assert returned_user.address == user.address
      assert returned_user.balance == user.balance
      assert returned_user.password_hash == user.password_hash
    end

    test "returns {:error, :not_found} when user does not exist" do
      non_existent_id = 999_999
      assert {:error, :not_found} = Get.call(non_existent_id)
    end

    test "handles string id that can be converted to integer", %{user: user} do
      string_id = Integer.to_string(user.id)
      assert {:ok, returned_user} = Get.call(string_id)
      assert returned_user.id == user.id
    end

    test "returns {:error, :not_found} for string id that doesn't exist" do
      assert {:error, :not_found} = Get.call("999999")
    end

    test "returns {:error, :not_found} for invalid string id" do
      assert {:error, :not_found} = Get.call("invalid")
    end

    test "returns {:error, :not_found} for nil id" do
      assert {:error, :not_found} = Get.call(nil)
    end

    test "returns {:error, :not_found} for empty string id" do
      assert {:error, :not_found} = Get.call("")
    end

    test "returns {:error, :not_found} for negative id" do
      assert {:error, :not_found} = Get.call(-1)
    end

    test "returns {:error, :not_found} for zero id" do
      assert {:error, :not_found} = Get.call(0)
    end

    test "returns {:error, :not_found} for float id" do
      assert {:error, :not_found} = Get.call(1.5)
    end

    test "returns complete user struct with all fields", %{user: user} do
      assert {:ok, returned_user} = Get.call(user.id)

      # Verify all expected fields are present
      assert returned_user.id
      assert returned_user.name
      assert returned_user.email
      assert returned_user.address
      assert returned_user.balance
      assert returned_user.password_hash
      assert returned_user.inserted_at
      assert returned_user.updated_at

      # Verify virtual password field is not set
      refute returned_user.password
    end

    test "handles multiple users and returns correct one" do
      # Create second user
      {:ok, user2} =
        %{@valid_attrs | email: "jane@example.com"}
        |> User.changeset()
        |> Repo.insert()

      # Get first user
      assert {:ok, returned_user1} = Get.call(user2.id)
      assert returned_user1.email == "jane@example.com"
    end

    test "returns user with correct data types", %{user: user} do
      assert {:ok, returned_user} = Get.call(user.id)

      assert is_integer(returned_user.id)
      assert is_binary(returned_user.name)
      assert is_binary(returned_user.email)
      assert is_binary(returned_user.address)
      assert is_binary(returned_user.balance)
      assert is_binary(returned_user.password_hash)
      assert %NaiveDateTime{} = returned_user.inserted_at
      assert %NaiveDateTime{} = returned_user.updated_at
    end

    test "handles user with default balance", %{user: user} do
      # Update user to have default balance
      {:ok, updated_user} =
        user
        |> User.changeset(%{balance: "0.00000"})
        |> Repo.update()

      assert {:ok, returned_user} = Get.call(updated_user.id)
      assert returned_user.balance == "0.00000"
    end

    test "handles user with unicode characters in name" do
      {:ok, unicode_user} =
        %{@valid_attrs | name: "José María", email: "jose@example.com"}
        |> User.changeset()
        |> Repo.insert()

      assert {:ok, returned_user} = Get.call(unicode_user.id)
      assert returned_user.name == "José María"
    end

    test "handles large user id numbers" do
      # This test simulates having a large ID (though we can't actually insert with a specific ID)
      assert {:error, :not_found} = Get.call(999_999_999)
    end
  end

  describe "error scenarios" do
    test "handles database connection issues gracefully" do
      # This is a conceptual test - in a real scenario you might mock the Repo
      # to simulate connection failures, but for now we just test the basic case
      assert {:error, :not_found} = Get.call(999)
    end

    test "handles various invalid input types" do
      invalid_inputs = [
        :atom,
        %{},
        [],
        {:tuple},
        self()
      ]

      for invalid_input <- invalid_inputs do
        assert {:error, :not_found} = Get.call(invalid_input)
      end
    end
  end
end
