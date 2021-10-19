require 'byebug'

describe LatePoliciesController do

  let(:instructor) { build(:instructor, id: 6) }
  before(:each) do
    stub_current_user(instructor, instructor.role.name, instructor.role)
  end

  context "#request new" do
    it 'renders template' do
      get :new
      expect(response).to render_template(:new)
    end

    it 'shows error on empty submission' do
      get :new
      params = {
        late_policy: {
            policy_name: '',
            penalty_per_unit: '',
            penalty_unit: '',
            max_penalty: 0,
        }
      }

      byebug
      post :create, params
      expect(flash[:error]).to include("Policy name can't be blank")
      expect(flash[:error]).to include("Penalty per unit can't be blank")
    end

    it 'shows error on penalty per unit being negative' do
      get :new
      params = {
        late_policy: {
            policy_name: 'assignment 1',
            penalty_per_unit: 'Minute',
            penalty_unit: 10,
            max_penalty: 0,
        }
      }
      byebug
      post :create, params
      expect(flash[:error]).to include("Max penalty must be greater than 0")
    end

    it 'shows error on max penalty being less than penalty per unit' do
      get :new
      params = {
        late_policy: {
            policy_name: 'assignment 1',
            penalty_per_unit: 'Minute',
            penalty_unit: -10,
            max_penalty: -100,
        }
      }
      byebug
      post :create, params
      expect(flash[:error]).to include("The maximum penalty cannot be less than penalty per unit.")
    end

    # shows error
    it 'shows error on policy name greater than 255 characters' do
      get :new
      params = {
        late_policy: {
            policy_name: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            penalty_per_unit: 1,
            penalty_unit: 'Minute',
            max_penalty: 10,
        }
      }
      byebug
      post :create, params
      expect(flash[:error]).to include("Policy name is invalid")
    end
    
    # error
    it 'shows error on policy per unit is random string' do
      get :new
      params = {
        late_policy: {
            policy_name: 'assignment 1',
            penalty_per_unit: 10,
            penalty_unit: 'xyz',
            max_penalty: 50,
        }
      }
      byebug
      post :create, params
      expect(flash[:error]).to include("Policy per unit should be days/hours/minutes")
      expect(flash[:error]).to include("Policy per unit should be days/hours/minutes")
    end

    # it 'basic happy flow test' do
    #   get :new
    #   params = {
    #     late_policy: {
    #         policy_name: 'assignment 1',
    #         penalty_per_unit: 10,
    #         penalty_unit: 'Minute',
    #         max_penalty: 50,
    #     }
    #   }
    #   # byebug
    #   post :create, params
    #   expect(flash[:error]).to include("Successfully saved")
    # end

    # it 'basic test to test all limits' do
    #   get :new
    #   params = {
    #     late_policy: {
    #         policy_name: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    #         penalty_per_unit: 50,
    #         penalty_unit: 'Minute',
    #         max_penalty: 50,
    #     }
    #   }
    #   byebug
    #   post :create, params
    #   expect(flash[:error]).to include("Successfully saved")
    # end
  end
end