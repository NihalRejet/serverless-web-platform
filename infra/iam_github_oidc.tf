# Lets GitHub Actions get short-lived AWS credentials through OIDC, so no AWS
# access keys are stored in GitHub.
resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  # Required by the provider schema. AWS now validates GitHub's certificate
  # itself, so this value is not used for trust decisions.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only this repository, and only pull requests or the main branch.
    # Repositories created after July 2026 use GitHub's immutable subject
    # format, which includes the owner and repository IDs.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:NihalRejet@145046577/serverless-web-platform@1416685364:pull_request",
        "repo:NihalRejet@145046577/serverless-web-platform@1416685364:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "swp-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_policy.json
}

# Known limitation: broader than the pipeline needs. Narrowing this to the
# exact actions Terraform and the deploy steps use is the next hardening step.
resource "aws_iam_role_policy_attachment" "github_actions_role_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
