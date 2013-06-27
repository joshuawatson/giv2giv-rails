require 'spec_helper'

describe Api::CharityGroupController do

  before(:each) do
   @cg = default_charity_group
  end

  describe "index" do
    it "should not require prior authentication" do
      get :index, :format => :json
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp.first['name'].should == default_charity_group.name
    end

    it "should work" do
      setup_authenticated_session
      get :index, :format => :json
      response.status.should == 200
    end
  end # end index

  describe "create" do
    it "should require prior authentication" do
      post :create, :format => :json, :charity_group => {}
      response.status.should == 401
    end

    it "should include errors on failure" do
      setup_authenticated_session
      post :create, :format => :json, :charity_group => {}
      response.status.should == 422
      resp = JSON.parse(response.body)
      resp['name'].should_not be_blank
      resp['charities'].should_not be_blank
    end

    it "should work" do
      setup_authenticated_session
      post :create, :format => :json, :charity_group => { :name => 'Something', :charity_ids => [default_charity_1.id] }
      response.status.should == 201
      resp = JSON.parse(response.body)
      resp['id'].should_not be_blank
      resp_char = resp['charities'].first
      resp_char['id'].should == default_charity_1.id
      resp_char['ein'].should == default_charity_1.ein
    end
  end # end create

  describe "show" do
    it "should not require prior authentication" do
      get :show, :format => :json, :id => @cg.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @cg.name
      resp['id'].should == @cg.id
    end

    it "should work" do
      setup_authenticated_session
      get :show, :format => :json,:id => @cg.id
      response.status.should == 200
      resp = JSON.parse(response.body)
      resp['name'].should == @cg.name
      resp['id'].should == @cg.id
    end

    it "should not be found" do
      setup_authenticated_session
      id = 12354
      CharityGroup.find(id).should be_nil
      get :show, :format => :json, :id => id
      response.status.should == 404
    end
  end # end show

end
