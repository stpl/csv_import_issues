  resources :projects do
    resources :csv_imports, :path_names => {:csv_imports => 'imports'} do
      collection do
        get :download
        post :create_issue
      end
    end
  end
