require 'spec_helper'

describe VacanciesController do
  let(:vacancy){ stub_model(Vacancy) }
  
  describe "GET 'index'" do
    before do
      Vacancy.stub_chain(:available, :page, :per).and_return([vacancy])
    end
    
    it "should get only available vacancies" do
      Vacancy.should_receive(:available)
      get 'index'
    end
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'new'" do
    before do
      Vacancy.stub!(:new => vacancy.as_new_record)
    end
    
    it "should create a new vacancy" do
      Vacancy.should_receive(:new)
      get 'new'
    end
    it "should be successful" do
      get 'new'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    before do
      Vacancy.stub!(:new => vacancy)
      VacancyMailer.stub_chain(:creation_notice, :deliver)
    end
    
    it "should create a new vacancy" do
      Vacancy.should_receive(:new)
      post 'create'
    end
    it "should store vacancy's data to database" do
      vacancy.should_receive(:save)
      post 'create'
    end
    
    context "when vacancy has been saved" do
      before{ vacancy.stub!(:save => true) }

      it "should deliver email notification" do
        VacancyMailer.should_receive(:creation_notice).with(vacancy)
        post 'create'
      end
      it "should set flash notification" do
        post 'create'
        flash.should_not be_blank
      end
      it "should response with redirect to root page" do
        post 'create'
        response.should redirect_to root_url
      end
    end
    context "when vacancy hasn't been saved because of errors" do
      before{ vacancy.stub!(:save => false, :errors => { :error => "foo" }) }
      
      it "should be successful" do
        post 'create'
        response.should be_success
      end
      it "should render 'new' template" do
        post 'create'
        response.should render_template('new')
      end
    end
  end
  
  describe "GET 'show'" do
    before{ Vacancy.stub!(:find_by_id! => vacancy) }
    context "when vacancy has been approved" do
      before{ vacancy.stub!(:approved? => true) }
      
      it "should be success" do
        get 'show', :id => vacancy
        response.should be_success
      end
    end
    context "when vacancy hasn't been approved" do
      before{ vacancy.stub!(:approved? => false, :token => "foo") }

      context "and visitor has owner token" do
        it "should be success" do
          get 'show', :id => vacancy, :token => vacancy.token
          response.should be_success
        end
      end
      context "and visitor has admin token" do
        it "should be success" do
          get 'show', :id => vacancy, :token => vacancy.token
          response.should be_success
        end
      end
      context "and visitor doesn't have any token" do
        it "should be not found" do
          get 'show', :id => vacancy
          response.should be_not_found
        end
        it "should render 404 page" do
          get 'show', :id => vacancy
          response.should render_template(:file => 'public/404.html')
        end
      end
    end
  end
end