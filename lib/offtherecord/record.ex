defmodule Offtherecord.Record do
  use Ash.Domain, extensions: [AshJsonApi.Domain]

  json_api do
    routes do
      base_route "/posts", Offtherecord.Record.Post do
        get :read
        index :read
        post :create
        patch :update, route: "/:id"
        delete :destroy, route: "/:id"
      end
    end
  end

  resources do
    resource Offtherecord.Record.Post
  end
end
