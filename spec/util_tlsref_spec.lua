local tlsref = require "prosody.util.tlsref";

describe("util.tlsref", function()
	local version_compare = require "prosody.util.human.io".simple_version_compare;

	describe("default version", function()
		it("is not greater than latest version", function ()
			local default_version = tlsref.get_default_version();
			local latest_version = tlsref.get_latest_version();
			assert.equal(false, version_compare(latest_version, default_version));
		end);

		it("is a known version", function ()
			assert.is_table(tlsref.get_profile(tlsref.get_default_version()));
		end);
	end);

	describe("latest version", function ()
		it("is a known version", function ()
			assert.is_table(tlsref.get_profile("latest"));
		end);

		it("is the first entry of get_valid_versions()", function ()
			local versions = tlsref.get_valid_versions();
			assert.equal(tlsref.get_latest_version(), versions[1]);
		end);
	end);

	describe("get_valid_versions()", function ()
		it("returns versions in descending order", function ()
			local versions = tlsref.get_valid_versions();
			assert.is_true(#versions >= 1);
			for i = 1, #versions-1 do
				-- versions[i] must sort before versions[i+1]
				assert.equal(false, version_compare(versions[i], versions[i+1]));
			end
		end);

		it("contains the default version", function ()
			local found = false;
			for _, v in ipairs(tlsref.get_valid_versions()) do
				if v == tlsref.get_default_version() then found = true; end
			end
			assert.is_true(found);
		end);
	end);

	describe("get_valid_profile_names()", function ()
		it("returns an error for unknown versions", function ()
			local names, err = tlsref.get_valid_profile_names("0.0");
			assert.is_nil(names);
			assert.equal("unknown-version", err);
		end);

		it("uses the default version when none is given", function ()
			assert.same(
				tlsref.get_valid_profile_names(tlsref.get_default_version()),
				tlsref.get_valid_profile_names()
			);
		end);

		it("accepts 'latest' as a version", function ()
			assert.same(
				tlsref.get_valid_profile_names(tlsref.get_latest_version()),
				tlsref.get_valid_profile_names("latest")
			);
		end);

		it("lists the most-preferred profile first", function ()
			for _, version in ipairs(tlsref.get_valid_versions()) do
				local names = tlsref.get_valid_profile_names(version);
				assert.equal("modern", names[1],
					("most-preferred profile should be first for version %s"):format(version));
			end
		end);
	end);

	describe("get_profile()", function ()
		it("returns the default profile of the default version when called with no arguments", function ()
			assert.equal(
				tlsref.get_profile(tlsref.get_default_version(), tlsref.get_default_profile_name()),
				tlsref.get_profile()
			);
		end);

		it("resolves 'latest' to the latest version", function ()
			assert.equal(
				tlsref.get_profile(tlsref.get_latest_version()),
				tlsref.get_profile("latest")
			);
		end);

		it("returns an error for unknown versions", function ()
			local profile, err = tlsref.get_profile("0.0");
			assert.is_nil(profile);
			assert.equal("unknown-version", err);
		end);

		it("returns an error for unknown profile names", function ()
			local profile, err = tlsref.get_profile(nil, "no-such-profile");
			assert.is_nil(profile);
			assert.equal("unknown-profile", err);
		end);

		it("returns an error for profiles absent from a given version", function ()
			-- 'old' was dropped from the 6.0 guidelines
			local profile, err = tlsref.get_profile("6.0", "old");
			assert.is_nil(profile);
			assert.equal("unknown-profile", err);
		end);

		it("resolves every advertised version/profile combination", function ()
			for _, version in ipairs(tlsref.get_valid_versions()) do
				for _, name in ipairs(tlsref.get_valid_profile_names(version)) do
					local profile, err = tlsref.get_profile(version, name);
					assert.is_table(profile,
						("get_profile(%q, %q) failed: %s"):format(version, name, err));
				end
			end
		end);
	end);

	describe("get_default_profile_name()", function ()
		it("returns an error for unknown versions", function ()
			local name, err = tlsref.get_default_profile_name("0.0");
			assert.is_nil(name);
			assert.equal("unknown-version", err);
		end);

		it("accepts 'latest' as a version", function ()
			assert.is_string(tlsref.get_default_profile_name("latest"));
		end);

		it("returns a profile name valid for every version", function ()
			for _, version in ipairs(tlsref.get_valid_versions()) do
				local name = tlsref.get_default_profile_name(version);
				assert.is_string(name);
				assert.is_table(tlsref.get_profile(version, name),
					("default profile %q missing from version %s"):format(name, version));
			end
		end);
	end);

	describe("profile contents", function ()
		it("every profile specifies a TLS protocol version", function ()
			for _, version in ipairs(tlsref.get_valid_versions()) do
				for _, name in ipairs(tlsref.get_valid_profile_names(version)) do
					local profile = tlsref.get_profile(version, name);
					assert.is_string(profile.protocol);
					assert.truthy(profile.protocol:match("^tlsv1"),
						("unexpected protocol %q in %s/%s"):format(profile.protocol, version, name));
				end
			end
		end);

		it("every profile specifies TLS 1.3 ciphersuites and curves", function ()
			for _, version in ipairs(tlsref.get_valid_versions()) do
				for _, name in ipairs(tlsref.get_valid_profile_names(version)) do
					local profile = tlsref.get_profile(version, name);
					assert.is_table(profile.ciphersuites);
					assert.is_true(#profile.ciphersuites > 0);
					assert.is_table(profile.curveslist);
					assert.is_true(#profile.curveslist > 0);
				end
			end
		end);
	end);
end);
