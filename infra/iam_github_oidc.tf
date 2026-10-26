resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_policy" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = ["${aws_iam_openid_connect_provider.github_oidc.arn}"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:NihalRejet@145046577/serverless-web-platform@1416685364:pull_request"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "swp-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_policy.json
}

resource "aws_iam_role_policy_attachment" "github_actions_role_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
