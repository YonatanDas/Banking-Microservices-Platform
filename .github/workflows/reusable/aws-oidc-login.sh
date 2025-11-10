    - uses: actions/checkout@v3

    - name: Make scripts executable
      run: chmod +x .github/workflows/reusable/*.sh

    - name: Configure AWS OIDC Access
      uses: aws-actions/configure-aws-credentials@v2
      with:
        role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/oidc-github
        aws-region: ${{ env.AWS_REGION }}
        audience: sts.amazonaws.com

    - name: AWS ECR Login
      uses: aws-actions/amazon-ecr-login@v1