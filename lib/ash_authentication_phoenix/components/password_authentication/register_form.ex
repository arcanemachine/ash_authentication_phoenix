defmodule AshAuthentication.Phoenix.Components.PasswordAuthentication.RegisterForm do
  use AshAuthentication.Phoenix.Overrides.Overridable,
    root_class: "CSS class for the root `div` element.",
    label_class: "CSS class for the `h2` element.",
    form_class: "CSS class for the `form` element.",
    slot_class: "CSS class for the `div` surrounding the slot.",
    disable_button_text: "Text for the submit button when the request is happening."

  @moduledoc """
  Generates a default registration form.

  ## Component hierarchy

  This is a child of `AshAuthentication.Phoenix.Components.PasswordAuthentication`.

  Children:

    * `AshAuthentication.Phoenix.Components.PasswordAuthentication.Input.identity_field/1`
    * `AshAuthentication.Phoenix.Components.PasswordAuthentication.Input.password_field/1`
    * `AshAuthentication.Phoenix.Components.PasswordAuthentication.Input.password_confirmation_field/1`
    * `AshAuthentication.Phoenix.Components.PasswordAuthentication.Input.submit/1`

  ## Props

    * `config` - The configuration map as per
      `AshAuthentication.authenticated_resources/1`.
      Required.
    * `label` - The text to show in the submit label.
      Generated from the configured action name (via
      `Phoenix.HTML.Form.humanize/1`) if not supplied.
      Set to `false` to disable.

  #{AshAuthentication.Phoenix.Overrides.Overridable.generate_docs()}
  """

  use Phoenix.LiveComponent

  alias AshAuthentication.{
    PasswordAuthentication,
    Phoenix.Components.PasswordAuthentication.Input
  }

  alias AshPhoenix.Form
  alias Phoenix.LiveView.{Rendered, Socket}
  import Phoenix.HTML.Form
  import AshAuthentication.Phoenix.Components.Helpers

  @doc false
  @impl true
  @spec update(Socket.assigns(), Socket.t()) :: {:ok, Socket.t()}
  def update(assigns, socket) do
    config = assigns.config

    action =
      PasswordAuthentication.Info.password_authentication_register_action_name!(config.resource)

    confirm? =
      PasswordAuthentication.Info.password_authentication_confirmation_required?(config.resource)

    form =
      config.resource
      |> Form.for_action(action,
        api: config.api,
        as: to_string(config.subject_name),
        id: "#{PasswordAuthentication.provides(config.resource)}_#{config.subject_name}_#{action}"
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(form: form, trigger_action: false, confirm?: confirm?)
      |> assign_new(:label, fn -> humanize(action) end)
      |> assign_new(:inner_block, fn -> nil end)

    {:ok, socket}
  end

  @doc false
  @impl true
  @spec render(Socket.assigns()) :: Rendered.t() | no_return
  def render(assigns) do
    ~H"""
    <div class={override_for(@socket, :root_class)}>
      <%= if @label do %>
        <h2 class={override_for(@socket, :label_class)}>
          <%= @label %>
        </h2>
      <% end %>

      <.form
        :let={form}
        for={@form}
        phx-change="change"
        phx-submit="submit"
        phx-trigger-action={@trigger_action}
        phx-target={@myself}
        action={
          route_helpers(@socket).auth_callback_path(
            @socket.endpoint,
            :callback,
            @config.subject_name,
            @provider.provides(@config.resource)
          )
        }
        method="POST"
        class={override_for(@socket, :form_class)}
      >
        <%= hidden_input(form, :action, value: "register") %>

        <Input.identity_field socket={@socket} config={@config} form={form} />
        <Input.password_field socket={@socket} config={@config} form={form} />

        <%= if @confirm? do %>
          <Input.password_confirmation_field socket={@socket} config={@config} form={form} />
        <% end %>

        <%= if @inner_block do %>
          <div class={override_for(@socket, :slot_class)}>
            <%= render_slot(@inner_block) %>
          </div>
        <% end %>

        <Input.submit
          socket={@socket}
          config={@config}
          form={form}
          action={:register}
          disable_text={override_for(@socket, :disable_button_text)}
        />
      </.form>
    </div>
    """
  end

  @doc false
  @impl true
  @spec handle_event(String.t(), %{required(String.t()) => String.t()}, Socket.t()) ::
          {:noreply, Socket.t()}

  def handle_event("change", params, socket) do
    config = socket.assigns.config
    params = Map.get(params, to_string(config.subject_name))

    form =
      socket.assigns.form
      |> Form.validate(params, errors: false)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", params, socket) do
    params = Map.get(params, to_string(socket.assigns.config.subject_name))

    form = Form.validate(socket.assigns.form, params)

    socket =
      socket
      |> assign(:form, form)
      |> assign(:trigger_action, form.valid?)

    {:noreply, socket}
  end
end
