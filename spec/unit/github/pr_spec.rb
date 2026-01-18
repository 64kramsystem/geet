# frozen_string_literal: true
# typed: false

require 'spec_helper'

require_relative '../../../lib/geet/github/pr'
require_relative '../../../lib/geet/github/api_interface'

describe Geet::Github::PR do
  describe '#fetch_available_merge_method' do
    let(:api_interface) { instance_double(Geet::Github::ApiInterface) }
    let(:pr_number) { 123 }
    let(:pr_title) { 'Test PR' }
    let(:pr_link) { 'https://github.com/owner/repo/pull/123' }
    let(:node_id) { 'PR_node_id_123' }
    let(:repository_path) { 'owner/repo' }

    subject { described_class.new(pr_number, api_interface, pr_title, pr_link, node_id: node_id) }

    before do
      allow(api_interface).to receive(:repository_path).and_return(repository_path)
    end

    context 'when there is one commit and squash merge is allowed' do
      it 'returns SQUASH' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => true,
            'squashMergeAllowed' => true,
            'rebaseMergeAllowed' => true,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 1,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        result = subject.send(:fetch_available_merge_method)
        expect(result).to eq('SQUASH')
      end
    end

    context 'when there is one commit but squash merge is not allowed' do
      it 'returns MERGE if merge commit is allowed' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => true,
            'squashMergeAllowed' => false,
            'rebaseMergeAllowed' => true,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 1,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        result = subject.send(:fetch_available_merge_method)
        expect(result).to eq('MERGE')
      end
    end

    context 'when there are multiple commits and merge commit is allowed' do
      it 'returns MERGE' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => true,
            'squashMergeAllowed' => true,
            'rebaseMergeAllowed' => true,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 3,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        result = subject.send(:fetch_available_merge_method)
        expect(result).to eq('MERGE')
      end
    end

    context 'when there are multiple commits and merge commit is not allowed' do
      it 'returns SQUASH if squash merge is allowed' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => false,
            'squashMergeAllowed' => true,
            'rebaseMergeAllowed' => true,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 3,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        result = subject.send(:fetch_available_merge_method)
        expect(result).to eq('SQUASH')
      end

      it 'returns REBASE if only rebase merge is allowed' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => false,
            'squashMergeAllowed' => false,
            'rebaseMergeAllowed' => true,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 3,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        result = subject.send(:fetch_available_merge_method)
        expect(result).to eq('REBASE')
      end
    end

    context 'when no merge methods are allowed' do
      it 'raises an error' do
        graphql_response = {
          'repository' => {
            'mergeCommitAllowed' => false,
            'squashMergeAllowed' => false,
            'rebaseMergeAllowed' => false,
            'pullRequest' => {
              'commits' => {
                'totalCount' => 3,
              },
            },
          },
        }

        expect(api_interface).to receive(:send_graphql_request)
          .with(anything, variables: {owner: 'owner', name: 'repo', number: pr_number})
          .and_return(graphql_response)

        expect { subject.send(:fetch_available_merge_method) }.to raise_error('No merge methods are allowed on this repository')
      end
    end
  end
end
