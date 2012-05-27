require "grape"

module Manifesto
  module API
    class V1 < Grape::API
      version 'v1', :using => :header, :vendor => 'manifesto'

      http_basic do |user, password|
        APIKey.where(:username => user, :key => password).first
      end

      resource :manifests do
        get ':name' do
          if @manifest = Manifest.where(:name => params[:name]).first
            @manifest
          else
            status 404
          end
        end

        put ':name' do
          @manifest = Manifest.where(:name => params[:name]).first
          manifest = JSON.parse(request.body.read.to_s)
          if @manifest.update(manifest)
            201
          else
            500
          end
        end

        delete ':name' do
          @manifest = Manifest.where(:name => params[:name]).first
          if @manifest.destroy
            200
          else
            500
          end
        end

        get ':name/current' do
          @manifest = Manifest.where(:name => params[:name]).first
          @manifest.current.components
        end

        get ':name/releases' do
          @manifest = Manifest.where(:name => params[:name]).first
          @manifest.releases
        end

        post ':name/release' do
          @manifest = Manifest.where(:name => params[:name]).first
          if @release = @manifest.release(JSON.parse(request.body.read.to_s))
            @release
          else
            403
          end
        end

        post ':name/fork' do
          @manifest = Manifest.where(:name => params[:name]).first

          if @fork = @manifest.fork(JSON.parse(request.body.read.to_s))
            @fork
          else
            500
          end
        end

        post ':name/follow' do
          follower = JSON.parse(request.body.read.to_s)
          @manifest = Manifest.where(:name => params[:name]).first

          if @manifest.add_follower(follower)
            201
          else
            500
          end
        end
      end
    end
  end
end
